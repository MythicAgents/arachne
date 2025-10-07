from mythic_container.C2ProfileBase import *
from pathlib import Path


class Webshell(C2Profile):
    name = "webshell"
    description = "P2P definition for interacting with a remote webshell through an agent"
    author = "@its_a_feature_"
    semver = "0.0.1"
    is_p2p = True
    is_server_routed = False
    agent_icon_path = Path(".") / "webshell" / "webshell.svg"
    server_folder_path = Path(".") / "c2_code"
    server_binary_path = server_folder_path / "server.py"
    parameters = [
        C2ProfileParameter(name="user_agent",
                           description="User Agent",
                           default_value="Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko"),
        C2ProfileParameter(name="cookie_name",
                           parameter_type=ParameterType.String,
                           description="cookie name for authing to webshell",
                           default_value="session", required=False),
        C2ProfileParameter(name="query_param",
                           parameter_type=ParameterType.String,
                           description="query parameter for GET requests",
                           default_value="id", required=False),
        C2ProfileParameter(name="url",
                           parameter_type=ParameterType.String,
                           description="Remote URL to target where agent will live or redirector that will forward the message",
                           default_value="https://example.com/evil.aspx", required=True),
    ]

    async def config_check(self, inputMsg: C2ConfigCheckMessage) -> C2ConfigCheckMessageResponse:
        try:
            return C2ConfigCheckMessageResponse(Success=True, Message="Success")
        except Exception as e:
            return C2ConfigCheckMessageResponse(Success=False, Error=str(sys.exc_info()[-1].tb_lineno) + str(e))

    async def redirect_rules(self, inputMsg: C2GetRedirectorRulesMessage) -> C2GetRedirectorRulesMessageResponse:
        """Generate Apache ModRewrite rules given the Payload's C2 configuration

        :param inputMsg: Payload's C2 Profile configuration
        :return: C2GetRedirectorRulesMessageResponse detailing some Apache ModRewrite rules for the payload
        """
        return C2GetRedirectorRulesMessageResponse(Success=True, Message="#Not Implemented")

    async def host_file(self, inputMsg: C2HostFileMessage) -> C2HostFileMessageResponse:
        """Host a file through a c2 channel

        :param inputMsg: The file UUID to host and which URL to host it at
        :return: C2HostFileMessageResponse detailing success or failure to host the file
        """
        response = C2HostFileMessageResponse(Success=False)
        try:
            response.Error = "Can't host files through a p2p profile"
        except Exception as e:
            response.Error = f"{e}"
        return response

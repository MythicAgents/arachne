import json
import base64
import asyncio

from mythic_container.TranslationBase import *


class ArachneTranslator(TranslationContainer):
    name = "arachne_translator"
    description = "python translation service for Arachne webshell"
    author = "@its_a_feature_"

    async def generate_keys(self, inputMsg: TrGenerateEncryptionKeysMessage) -> TrGenerateEncryptionKeysMessageResponse:
        response = TrGenerateEncryptionKeysMessageResponse(Success=True)
        response.DecryptionKey = b""
        response.EncryptionKey = b""
        return response

    async def translate_to_c2_format(self,
                                     inputMsg: TrMythicC2ToCustomMessageFormatMessage) -> TrMythicC2ToCustomMessageFormatMessageResponse:
        response = TrMythicC2ToCustomMessageFormatMessageResponse(Success=True)
        if "tasks" in inputMsg.Message:
            if len(inputMsg.Message["tasks"]) > 0:
                response.Message = inputMsg.Message["tasks"][0]["parameters"].encode("UTF8")
            else:
                response.Message = b""
        else:
            response.Message = b""
        return response

    async def translate_from_c2_format(self,
                                       inputMsg: TrCustomMessageToMythicC2FormatMessage) -> TrCustomMessageToMythicC2FormatMessageResponse:
        response = TrCustomMessageToMythicC2FormatMessageResponse(Success=True)
        response_pieces = inputMsg.Message.decode("UTF8").split("|")
        response.Message = {
            "action": "post_response",
            "responses": [
                {
                    "task_id": response_pieces[0],
                    "process_response": "|".join(response_pieces[1:]),
                    "completed": True
                }
            ]}
        return response

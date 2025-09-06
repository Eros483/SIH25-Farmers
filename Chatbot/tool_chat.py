import os
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.memory import ConversationBufferWindowMemory
from langchain.chains import ConversationChain
from langchain.prompts import PromptTemplate
from dotenv import load_dotenv
from Chatbot.prompt import define_prompt

load_dotenv()
chat_prompt = define_prompt()

class GeminiChatbot:
    def __init__(self, api_key=None, memory_size=10):
        self.api_key = api_key or os.getenv("GOOGLE_API_KEY")
        
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=self.api_key,
            temperature=0.7
        )

        self.memory = ConversationBufferWindowMemory(
            k=memory_size,
            return_messages=True
        )
        
        self.prompt_template = PromptTemplate(
            template=f"""{chat_prompt}
            Previous conversation:
            {{history}}

            Current message:
            Human: {{input}}
            Assistant: """,
            input_variables=["history", "input"]
        )
        
        self.conversation = ConversationChain(
            llm=self.llm,
            memory=self.memory,
            prompt=self.prompt_template,
            verbose=False
        )
    
    def chat(self, message):
        try:
            return self.conversation.predict(input=message)
        except Exception as e:
            return f"Error: {str(e)}"
    
    def clear_memory(self):
        self.memory.clear()
    
    def get_memory(self):
        return self.memory.buffer

bot=GeminiChatbot()
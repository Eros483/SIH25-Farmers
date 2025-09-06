import os
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.memory import ConversationBufferWindowMemory
from langchain.chains import ConversationChain
from langchain.prompts import PromptTemplate

class GeminiChatbot:
    def __init__(self, api_key, custom_prompt=None, memory_size=10):
        """
        Initialize the chatbot with Gemini and memory
        
        Args:
            api_key (str): Google API key for Gemini
            custom_prompt (str): Your custom system prompt
            memory_size (int): Number of conversation turns to remember
        """
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-pro",
            google_api_key=api_key,
            temperature=0.7, 
            convert_system_message_to_human=True 
        )

        self.memory = ConversationBufferWindowMemory(
            k=memory_size,
            return_messages=True
        )
        
        # Set up custom prompt template
        if custom_prompt is None:
            custom_prompt = """You are a helpful AI assistant. You have memory of our conversation and can refer to previous messages. Be friendly, informative, and helpful."""
        
        self.prompt_template = PromptTemplate(
            template=f"""{custom_prompt}

            Previous conversation:
            {{history}}

            Current message:
            Human: {{input}}
            Assistant: """,
            input_variables=["history", "input"]
        )
        
        # Create conversation chain
        self.conversation = ConversationChain(
            llm=self.llm,
            memory=self.memory,
            prompt=self.prompt_template,
            verbose=False  # Set to True to see what's happening
        )
    
    def chat(self, message):
        """Send a message to the chatbot and get response"""
        try:
            response = self.conversation.predict(input=message)
            return response
        except Exception as e:
            return f"Error: {str(e)}"
    
    def clear_memory(self):
        """Clear the conversation memory"""
        self.memory.clear()
        print("Memory cleared!")
    
    def get_memory(self):
        """Get current conversation history"""
        return self.memory.buffer
    
    def update_prompt(self, new_prompt):
        """Update the system prompt"""
        self.prompt_template = PromptTemplate(
            template=f"""{new_prompt}
            Previous conversation:
            {{history}}

            Current message:
            Human: {{input}}
            Assistant: """,
            input_variables=["history", "input"]
        )
        self.conversation.prompt = self.prompt_template
        print("Prompt updated!")

def main():
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("Please set your GOOGLE_API_KEY environment variable")
        return
    
    custom_prompt = """You are a knowledgeable coding assistant. You remember our conversation and can help with programming questions. You're patient, detailed, and provide practical examples. If I mention a specific language or framework, remember that context for future responses."""
    
    # Initialize chatbot
    bot = GeminiChatbot(
        api_key=api_key,
        custom_prompt=custom_prompt,
        memory_size=20  # Remember last 20 exchanges
    )
    
    print("Gemini Chatbot with Memory - Ready!")
    print("Type 'quit' to exit, 'clear' to clear memory, or 'memory' to see conversation history")
    print("-" * 50)
    
    while True:
        user_input = input("\nYou: ")
        
        if user_input.lower() == 'quit':
            break
        elif user_input.lower() == 'clear':
            bot.clear_memory()
            continue
        elif user_input.lower() == 'memory':
            print(f"\nConversation History:\n{bot.get_memory()}")
            continue
        
        response = bot.chat(user_input)
        print(f"\nBot: {response}")

if __name__ == "__main__":
    main()

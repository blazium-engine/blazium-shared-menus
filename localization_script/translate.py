from openai import OpenAI
from dotenv import load_dotenv
import os
load_dotenv()
client = OpenAI()

languages = []
langages_dict = {}
# read ../lang directory for all files
for file in os.listdir("../lang"):
    if file.endswith(".po"):
        language = file.split(".")[0]
        langages_dict[language] = true
        languages.append(language)
# Read input from cmdline
if len(os.sys.argv) > 1:
    word = os.sys.argv[1]
else:
    print("No word provided, using default 'cat'.")
    word = "cat"

response = client.responses.create(
    model="gpt-4.1",
    input="Translate the following: \"" + word + "\". As output give me on each line the language code and translated word, csv format. Translate to the following languages:\n" + ",".join(languages),
)
print(response.output_text)

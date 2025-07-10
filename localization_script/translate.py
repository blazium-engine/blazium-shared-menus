from openai import OpenAI
from dotenv import load_dotenv
import os
load_dotenv()
client = OpenAI()

languages = []
# read ../lang directory for all files
for file in os.listdir("../lang"):
    if file.endswith(".po"):
        language = file.split(".")[0]
        languages.append(language)
# Read input from cmdline
if len(os.sys.argv) > 1:
    word = os.sys.argv[1]
else:
    print("No word provided, using default 'cat'.")
    word = "cat"

response = client.responses.create(
    model="gpt-4o",
    input="Translate the following: \"\"" + word + "\"\". As output give me exactly: on each line the language code and translated word, csv format. Translate to the following languages:\n" + ",".join(languages),
)

written_out = 0
# Write them to input.csv
with open("input.csv", "w") as f:
    f.write("lang,translation\n")
    for line in response.output_text.split("\n"):
        for lang in languages:
            if line.strip().startswith(lang + ","):
                f.write(line.strip() + "\n")
                written_out += 1

print(f"Wrote {written_out} translations to input.csv.")
if written_out != len(languages):
    print(f"Warning: Not all languages were translated. Expected {len(languages)}, got {written_out}.")

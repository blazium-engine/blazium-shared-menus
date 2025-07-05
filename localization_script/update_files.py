import csv
import os
import polib

folder_path = "../lang"
msg_id = ""
if len(os.sys.argv) > 1:
    msg_id = os.sys.argv[1]
    if len(os.sys.argv) > 2:
        folder_path = os.sys.argv[2]
    else:
        print("No folder_path provided, using default '../lang'.")
# Readt input.csv file
if msg_id == "":
    print("No msg_id provided. Sorting translations only")
    for lang in os.listdir(folder_path):
        po_file_path = f"{folder_path}/{lang}"
        print(po_file_path)
        pofile = polib.pofile(po_file_path, check_for_duplicates=True)
        pofile.sort()
        pofile.save(po_file_path)
        print(f"Sorted {po_file_path} with translation for {translation}.")
    exit(0)
with open("input.csv", "r") as f:
    reader = csv.DictReader(f)
    translations = {row['lang']: row['translation'] for row in reader}
    translations["localization"] = ""
    for lang, translation in translations.items():
        po_file_path = f"{folder_path}/{lang}.po"
        if lang == "localization":
            po_file_path = f"{folder_path}/{lang}.pot"
        print(f"Adding {po_file_path} with translation for {translation}.")
        pofile = polib.pofile(po_file_path, check_for_duplicates=True)
        entry = pofile.find(msg_id)
        if entry:
            pofile.remove(entry)
        pofile.append(polib.POEntry(msgid=msg_id, msgstr=translation))
        pofile.sort()
        pofile.save(po_file_path)

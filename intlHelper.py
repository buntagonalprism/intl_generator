from subprocess import check_output
import glob, os
import sys
if len(sys.argv) == 2:
	if sys.argv[1] == 'export':
		exportResult = check_output("flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/strings.intl.dart", shell=True)
		print(exportResult.decode('UTF-8'))
		print("Export complete. Created intl_messages.arb.")
	elif sys.argv[1] == 'import':
		command = "flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/strings.intl.dart"
		fileCount = 0
		for file in glob.glob(".\lib\l10n\intl_*.arb"):
			if "intl_messages.arb" not in file:
				command = command + " " + file
				fileCount = fileCount + 1
				
		if fileCount == 0:
			print("No suitable ARB files found. Copy the base intl_messages.arb file, and have it translated. Translated files should have their language code as a prefix, e.g. intl_en.arb, intl_zh.arb");
		else: 
			importResult = check_output(command, shell=True)
			print(importResult.decode('UTF-8'))
			print("Import complete");
			
else:
	print("Specify either import or export mode")

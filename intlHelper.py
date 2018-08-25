from subprocess import check_output
import subprocess
import glob, os
import sys

def printHelp():
    print("Specify a mode. Available modes: ")
    print("export    Exports a generated strings.intl.dart file to ARB format for translating")
    print("import    Imports translated ARB files into formats usable by dart intl package")
    print("build     Runs the flutter build script once (not intl specific, just a shortcut")
    print("watch     Runs the flutter build script in watch mode, which automatically re-runs when files are changed (not intl specific)")
    
def runProcess(command):
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    for line in iter(p.stdout.readline, b''):
        # Remove unnecessary trailing newline which causes lots of spacing in output
        print(line[0:-1].decode('UTF-8'))
    

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
            print("Import complete")
    elif sys.argv[1] == 'build':
        runProcess("flutter packages pub run build_runner build")
    elif sys.argv[1] == 'watch':
        runProcess("flutter packages pub run build_runner watch")
    else:
        printHelp()
else:
    printHelp()
    


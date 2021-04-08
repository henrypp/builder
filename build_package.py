import argparse
import contextlib
import glob
import hashlib
import os
import shutil

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_clr (text, is_error=False):
	if is_error:
		print (f"{bcolors.FAIL}" + text + f"{bcolors.ENDC}")
	else:
		print (f"{bcolors.OKGREEN}" + text + f"{bcolors.ENDC}")

def copy_file (src, dst):
	shutil.copyfile (src, dst)

def remove_file (src):
	with contextlib.suppress (FileNotFoundError):
		os.remove (src)

def sign_file (src):
	dst = src + ".sig"
	remove_file (dst)
	os.system ("gpg --output \"" + dst + "\" --detach-sign \"" + src + "\"")

def copy_files (mask, dst):
	for fn in glob.glob (mask):
		shutil.copy (fn, dst)

def move_files (mask, dst):
	for fn in glob.glob (mask):
		shutil.move (fn, dst)

def sign_files (mask):
	for fn in glob.glob (mask):
		sign_file (fn)

def remove_files (mask):
	for fn in glob.glob (mask):
		remove_file (fn)

def pack_dir (out_file,  directory):
	os.system ("7z.exe a -mm=Deflate64 -mx=9 -mfb=257 -mpass=15 -mmt=on -mtc=off -slp -bb1 \"" + out_file + "\" \"" + directory + "\"")

def calculate_hash (src):
	with open (src, "rb") as fn:
		bytes = fn.read ()
		fn.close ()

		return hashlib.sha256 (bytes).hexdigest () + " *" + os.path.basename (src) + "\r\n"

# Colored terminal fix
os.system ('')

parser = argparse.ArgumentParser (add_help=False, description='Build project packages.')
parser.add_argument ('--name', help='project full name')
parser.add_argument ('--name-short', help='project short name', required=True)
parser.add_argument ('--version', help='project short name', required=True)

args = parser.parse_args ()

APP_NAME=args.name
APP_NAME_SHORT=args.name_short
APP_VERSION=args.version

# Set script configuration
CURRENT_DIRECTORY = os.path.dirname (os.path.abspath (__file__))
PROJECT_DIRECTORY = os.path.join (CURRENT_DIRECTORY, '..', APP_NAME_SHORT)
BIN_DIRECTORY = os.path.join (PROJECT_DIRECTORY, 'bin')
OUT_DIRECTORY = os.path.join (os.path.join (os.environ['USERPROFILE']), 'Desktop')
TMP_DIRECTORY = os.path.join (CURRENT_DIRECTORY, "temp", APP_NAME_SHORT)

PORTABLE_FILE = os.path.join (OUT_DIRECTORY, APP_NAME_SHORT + '-' + APP_VERSION + '-bin.zip')
PDB_PACKAGE_FILE = os.path.join (OUT_DIRECTORY, APP_NAME_SHORT + '-' + APP_VERSION + '-pdb.zip')
SETUP_FILE = os.path.join (OUT_DIRECTORY, APP_NAME_SHORT + '-' + APP_VERSION + '-setup.exe')
CHECKSUM_FILE = os.path.join (OUT_DIRECTORY, APP_NAME_SHORT + '-' + APP_VERSION + '.sha256')

# Check configuration is right
if not os.path.isdir (PROJECT_DIRECTORY):
	print_clr ('Project directory '' + PROJECT_DIRECTORY + '' was not found.',  True)
	os.sys.exit ()

if not os.path.isdir (BIN_DIRECTORY):
	print_clr ('Binaries directory '' + PROJECT_DIRECTORY + '' was not found.',  True)
	os.sys.exit ()

# Remove previous packages
print_clr ('Remove previous packages...')

remove_file (PORTABLE_FILE)
remove_file (PDB_PACKAGE_FILE)
remove_file (SETUP_FILE)
remove_file (SETUP_FILE + '.sig')
remove_file (CHECKSUM_FILE)

# Prepare for commits
if os.path.isfile (os.path.join (CURRENT_DIRECTORY, '.github', 'FUNDING.yml')) and not os.path.isfile (os.path.join (PROJECT_DIRECTORY, '.github', 'FUNDING.yml')):
	os.makedirs (os.path.join (PROJECT_DIRECTORY, '.github'), exist_ok=True)
	copy_file (os.path.join (CURRENT_DIRECTORY, '.github', 'FUNDING.yml'), os.path.join (PROJECT_DIRECTORY, '.github', 'FUNDING.yml'))

if os.path.isfile (os.path.join (CURRENT_DIRECTORY, '.editorconfig')) and not os.path.isfile (os.path.join (PROJECT_DIRECTORY, '.editorconfig')):
	copy_file (os.path.join (CURRENT_DIRECTORY, '.editorconfig'), os.path.join (PROJECT_DIRECTORY, '.editorconfig'))

if os.path.isfile (os.path.join (CURRENT_DIRECTORY, '.gitattributes')) and not os.path.isfile (os.path.join (PROJECT_DIRECTORY, '.gitattributes')):
	copy_file (os.path.join (CURRENT_DIRECTORY, '.gitattributes'), os.path.join (PROJECT_DIRECTORY, '.gitattributes'))

if os.path.isfile (os.path.join (CURRENT_DIRECTORY, '..gitignore')) and not os.path.isfile (os.path.join (PROJECT_DIRECTORY, '.gitignore')):
	copy_file (os.path.join (CURRENT_DIRECTORY, '..gitignore'), os.path.join (PROJECT_DIRECTORYPROJECT_DIRECTORY, '..gitignore'))

if os.path.isfile (os.path.join (CURRENT_DIRECTORY, '.gitmodules')) and not os.path.isfile (os.path.join (PROJECT_DIRECTORY, '.gitmodules')):
	copy_file (os.path.join (CURRENT_DIRECTORY, '.gitmodules'), os.path.join (PROJECT_DIRECTORY, '.gitmodules'))

if os.path.isfile (os.path.join (BIN_DIRECTORY, 'History.txt')):
	copy_file (os.path.join (BIN_DIRECTORY, 'History.txt'), os.path.join (PROJECT_DIRECTORY, 'CHANGELOG.md'))

# Prepare temporary directory
os.makedirs (os.path.join (TMP_DIRECTORY, '32'), exist_ok=True)
os.makedirs (os.path.join (TMP_DIRECTORY, '64'), exist_ok=True)

print_clr ('Create debug symbols package...')

if os.path.isfile (os.path.join (BIN_DIRECTORY, '32', APP_NAME_SHORT + '.pdb')):
	copy_file (os.path.join (BIN_DIRECTORY, '32', APP_NAME_SHORT + '.pdb'), os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.pdb'))

if os.path.isfile (os.path.join (BIN_DIRECTORY, '64', APP_NAME_SHORT + '.pdb')):
	copy_file (os.path.join (BIN_DIRECTORY, '64', APP_NAME_SHORT + '.pdb'), os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.pdb'))

pack_dir (PDB_PACKAGE_FILE, TMP_DIRECTORY)

remove_file (os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.pdb'))
remove_file (os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.pdb'))

print_clr ('Copy documentation...')

if os.path.isfile (os.path.join (BIN_DIRECTORY, 'Readme.txt')):
	copy_file (os.path.join (BIN_DIRECTORY, 'Readme.txt'), os.path.join (TMP_DIRECTORY, '32', 'Readme.txt'))
	copy_file (os.path.join (BIN_DIRECTORY, 'Readme.txt'), os.path.join (TMP_DIRECTORY, '64', 'Readme.txt'))

if os.path.isfile (os.path.join (BIN_DIRECTORY, 'History.txt')):
	copy_file (os.path.join (BIN_DIRECTORY, 'History.txt'), os.path.join (TMP_DIRECTORY, '32', 'History.txt'))
	copy_file (os.path.join (BIN_DIRECTORY, 'History.txt'), os.path.join (TMP_DIRECTORY, '64', 'History.txt'))

if os.path.isfile (os.path.join (BIN_DIRECTORY, 'License.txt')):
	copy_file (os.path.join (BIN_DIRECTORY, 'License.txt'), os.path.join (TMP_DIRECTORY, '32', 'License.txt'))
	copy_file (os.path.join (BIN_DIRECTORY, 'License.txt'), os.path.join (TMP_DIRECTORY, '64', 'License.txt'))

print_clr ('Copy configuration...')

if os.path.isfile (os.path.join (BIN_DIRECTORY, APP_NAME_SHORT + '.txt')):
	copy_file (os.path.join (BIN_DIRECTORY, APP_NAME_SHORT + '.txt'), os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.txt'))
	copy_file (os.path.join (BIN_DIRECTORY, APP_NAME_SHORT + '.txt'), os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.txt'))

with open (os.path.join (TMP_DIRECTORY, '32', 'portable.dat'), 'w', newline='') as f:
	data = f.write ('#PORTABLE#')

with open (os.path.join (TMP_DIRECTORY, '64', 'portable.dat'), 'w', newline='') as f:
	data = f.write ('#PORTABLE#')

copy_files (os.path.join (BIN_DIRECTORY, '*.bat'), os.path.join (TMP_DIRECTORY, '32'));
copy_files (os.path.join (BIN_DIRECTORY, '*.reg'), os.path.join (TMP_DIRECTORY, '32'));

copy_files (os.path.join (BIN_DIRECTORY, '*.bat'), os.path.join (TMP_DIRECTORY, '64'));
copy_files (os.path.join (BIN_DIRECTORY, '*.reg'), os.path.join (TMP_DIRECTORY, '64'));

print_clr ('Copy localization...')

if os.path.isfile (os.path.join (BIN_DIRECTORY, APP_NAME_SHORT + '.lng')):
	copy_file (os.path.join (BIN_DIRECTORY, APP_NAME_SHORT + '.lng'), os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.lng'))
	copy_file (os.path.join (BIN_DIRECTORY, APP_NAME_SHORT + '.lng'), os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.lng'))

print_clr ('Copy binaries...')

copy_files (os.path.join (BIN_DIRECTORY, '32', '*.exe'), os.path.join (TMP_DIRECTORY, '32'));
copy_files (os.path.join (BIN_DIRECTORY, '32', '*.scr'), os.path.join (TMP_DIRECTORY, '32'));
copy_files (os.path.join (BIN_DIRECTORY, '32', '*.dll'), os.path.join (TMP_DIRECTORY, '32'));

copy_files (os.path.join (BIN_DIRECTORY, '64', '*.exe'), os.path.join (TMP_DIRECTORY, '64'));
copy_files (os.path.join (BIN_DIRECTORY, '64', '*.scr'), os.path.join (TMP_DIRECTORY, '64'));
copy_files (os.path.join (BIN_DIRECTORY, '64', '*.dll'), os.path.join (TMP_DIRECTORY, '64'));

print_clr ('Signing binaries with gpg...')

sign_files (os.path.join (TMP_DIRECTORY, '32', '*.exe'))
sign_files (os.path.join (TMP_DIRECTORY, '32', '*.scr'))
sign_files (os.path.join (TMP_DIRECTORY, '32', '*.dll'))

sign_files (os.path.join (TMP_DIRECTORY, '64', '*.exe'))
sign_files (os.path.join (TMP_DIRECTORY, '64', '*.scr'))
sign_files (os.path.join (TMP_DIRECTORY, '64', '*.dll'))

print_clr ('Create portable package...')

pack_dir (PORTABLE_FILE, TMP_DIRECTORY)

if APP_NAME != '' and APP_NAME != None:
	print_clr ('Create setup package...')

	# Copy installer icon
	copy_file (os.path.join (PROJECT_DIRECTORY, "src", "res", "100.ico"), os.path.join (CURRENT_DIRECTORY, "logo.ico"))

	os.system ("makensis.exe /DAPP_FILES_DIR=" + TMP_DIRECTORY + " /DAPP_NAME=" + APP_NAME + " /DAPP_NAME_SHORT=" + APP_NAME_SHORT + " /DAPP_VERSION=" + APP_VERSION + " /X\"OutFile " + SETUP_FILE +"\" setup.nsi")

	sign_file (SETUP_FILE)

	remove_file (os.path.join (CURRENT_DIRECTORY, 'logo.ico'))

print_clr ('Calculate sha256 checksum for files...')

hash_string = ""

if os.path.isfile (PORTABLE_FILE):
	hash_string = hash_string + calculate_hash (PORTABLE_FILE)

if os.path.isfile (PDB_PACKAGE_FILE):
	hash_string = hash_string + calculate_hash (PDB_PACKAGE_FILE)

if os.path.isfile (SETUP_FILE):
	hash_string = hash_string + calculate_hash (SETUP_FILE)

hash_string = hash_string + '#32-bit\n'

if os.path.isfile (os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.exe')):
	hash_string = hash_string + calculate_hash (os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.exe'))

if os.path.isfile (os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.scr')):
	hash_string = hash_string + calculate_hash (os.path.join (TMP_DIRECTORY, '32', APP_NAME_SHORT + '.scr'))

hash_string = hash_string + '#64-bit\n'

if os.path.isfile (os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.exe')):
	hash_string = hash_string + calculate_hash (os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.exe'))

if os.path.isfile (os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.scr')):
	hash_string = hash_string + calculate_hash (os.path.join (TMP_DIRECTORY, '64', APP_NAME_SHORT + '.scr'))

if hash_string:
	with open (CHECKSUM_FILE, 'w', newline='') as f:
		f.write (hash_string)

print_clr ('Cleaning temporary files...')

shutil.rmtree (TMP_DIRECTORY)


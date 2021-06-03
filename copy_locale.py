import argparse
import configparser
import os
import shutil
import stat

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

def print_clr (text, clr=bcolors.OKGREEN):
	if clr == bcolors.FAIL:
		print (f"{bcolors.FAIL}" + text + f"{bcolors.ENDC}")
	elif clr == bcolors.OKGREEN:
		print (f"{bcolors.OKGREEN}" + text + f"{bcolors.ENDC}")
	elif clr == bcolors.WARNING:
		print (f"{bcolors.WARNING}" + text + f"{bcolors.ENDC}")
	elif clr == bcolors.HEADER:
		print (f"{bcolors.HEADER}" + text + f"{bcolors.ENDC}")
	else:
		print (text)

# Colored terminal fix
os.system ('')

parser = argparse.ArgumentParser (add_help=False, description='Build project locale.')
parser.add_argument ('--name-src', help='project short name source', required=True)
parser.add_argument ('--name-dst', help='project short name destination', required=True)
parser.add_argument ('--locale-key', help='key to found and replace', required=True)

args = parser.parse_args ()

APP_NAME_SHORT_SRC=args.name_src
APP_NAME_SHORT_DST=args.name_dst
LOCALE_KEY=args.locale_key

# Set current script configuration
CURRENT_DIRECTORY = os.path.dirname (os.path.abspath (__file__))
PROJECT_DIRECTORY_SRC = os.path.join (CURRENT_DIRECTORY, '..', APP_NAME_SHORT_SRC)
PROJECT_DIRECTORY_DST = os.path.join (CURRENT_DIRECTORY, '..', APP_NAME_SHORT_DST)
I18N_DIRECTORY_SRC = os.path.join (PROJECT_DIRECTORY_SRC, 'bin', 'i18n')
I18N_DIRECTORY_DST = os.path.join (PROJECT_DIRECTORY_DST, 'bin', 'i18n')

# Check configuration is right
if not os.path.isdir (PROJECT_DIRECTORY_SRC) or not os.path.isdir (PROJECT_DIRECTORY_DST):
	print_clr ('Project directory was not found.', bcolors.FAIL)
	os.sys.exit ()

if not os.path.isdir (I18N_DIRECTORY_SRC) or not os.path.isdir (I18N_DIRECTORY_DST):
	print_clr ('Locale directory was not found...', bcolors.FAIL);
	os.sys.exit ()

else:

	print_clr ('Start parsing localization key "' + LOCALE_KEY + '"...\n', 0)

	for f in os.listdir (I18N_DIRECTORY_DST):
		if not f.endswith ('.ini'):
			continue

		locale_name = os.path.splitext (f)[0]

		locale_path_src = os.path.join (I18N_DIRECTORY_SRC, f)

		if not os.path.isfile (locale_path_src):
			print_clr ('Locale "' + locale_name + '" was not found...', bcolors.FAIL)

		else:

			locale_ini_src = configparser.ConfigParser (delimiters='=')
			locale_ini_src.optionxform = str

			locale_ini_src.read (locale_path_src, encoding='utf-16')

			if not locale_name in locale_ini_src or not LOCALE_KEY in locale_ini_src[locale_name]:
				print_clr ('Locale "' + locale_name + '" key was not found...', bcolors.FAIL)

			else:
				locale_path_dst = os.path.join (I18N_DIRECTORY_DST, f)

				locale_ini_dst = configparser.ConfigParser (delimiters='=')
				locale_ini_dst.optionxform = str

				locale_ini_dst.read (locale_path_dst, encoding='utf-16')

				if not locale_name in locale_ini_dst:
					print_clr ('Locale "' + locale_name + '" was incorrect...', bcolors.FAIL)
					continue

				locale_value = locale_ini_src[locale_name][LOCALE_KEY]

				if LOCALE_KEY in locale_ini_dst[locale_name] and locale_ini_dst[locale_name][LOCALE_KEY] == locale_value:
					print_clr ('Locale "' + locale_name + '" have already localized...', bcolors.WARNING)
					continue

				print_clr ('Locale "' + locale_name + '" key was updated...')

				locale_ini_dst.set (locale_name, LOCALE_KEY, locale_value)

				# Update locale
				locale_content = ''

				with open (locale_path_dst, mode='r', encoding='utf-16') as ini_file:
					lines = ini_file.readlines ()
					ini_file.close ()

					for line in lines:
						if line.startswith (';'):
							locale_content = locale_content + line
						else:
							break

					if locale_content:
						locale_content = locale_content + '\n'

					locale_content = locale_content + '[' + locale_name + ']\n'
					ini_file.close ()

				for name,value in locale_ini_dst.items (locale_name, raw=True):
					locale_content = locale_content + name + '=' + value + '\n'

				with open (locale_path_dst, 'w', encoding='utf-16') as ini_file:
					ini_file.write (locale_content)
					ini_file.close ()

// xasm 3.1.0 by Piotr Fusik <fox@scene.pl>
// http://xasm.atari.org
// Can be compiled with DMD v2.073.

// Poetic License:
//
// This work 'as-is' we provide.
// No warranty express or implied.
// We've done our best,
// to debug and test.
// Liability for damages denied.
//
// Permission is granted hereby,
// to copy, share, and modify.
// Use as is fit,
// free or for profit.
// These rights, on this notice, rely.

import xasm : Xasm, AssemblyError;

import std.stdio;
import std.algorithm;
import std.range;

pure bool isOption(string arg) {
	if (arg.length < 2) return false;
	if (arg[0] == '-') return true;
	if (arg[0] != '/') return false;
	if (arg.length == 2) return true;
	if (arg[2] == ':') return true;
	return false;
}

int main(string[] args) {
	Xasm xasm = new Xasm;
	for (int i = 1; i < args.length; i++) {
		string arg = args[i];
		if (isOption(arg)) {
			char letter = arg[1];
			if (letter >= 'A' && letter <= 'Z')
				letter += 'a' - 'A';
			switch (letter) {
			case 'c':
			case 'i':
			case 'm':
			case 'p':
			case 'q':
			case 'u':
				if (arg.length != 2)
					xasm.exitCode = 3;
				xasm.setOption(letter);
				break;
			case 'd':
				string definition = null;
				if (arg[0] == '/') {
					if (arg.length >= 3 && arg[2] == ':')
						definition = arg[3 .. $];
				} else if (i + 1 < args.length && !isOption(args[i + 1]))
					definition = args[++i];
				if (definition is null || find(definition, '=').empty)
					xasm.exitCode = 3;
				xasm.commandLineDefinitions ~= definition;
				break;
			case 'l':
			case 't':
			case 'o':
				xasm.setOption(letter);
				string filename = null;
				if (arg[0] == '/') {
					if (arg.length >= 3 && arg[2] == ':')
						filename = arg[3 .. $];
				} else if (i + 1 < args.length && !isOption(args[i + 1]))
					filename = args[++i];
				if (filename is null && (letter == 'o' || arg.length != 2))
					xasm.exitCode = 3;
				xasm.optionParameters[letter - 'a'] = filename;
				break;
			default:
				xasm.exitCode = 3;
				break;
			}
			continue;
		}
		if (xasm.sourceFilename !is null)
			xasm.exitCode = 3;
		xasm.sourceFilename = arg;
	}
	if (xasm.sourceFilename is null)
		xasm.exitCode = 3;
	if (!xasm.getOption('q'))
		writeln(xasm.TITLE);
	if (xasm.exitCode != 0) {
		write(
`Syntax: xasm source [options]
/c             Include false conditionals in listing
/d:label=value Define a label
/i             Don't list included files
/l[:filename]  Generate listing
/o:filename    Set object file name
/M             Print Makefile rule
/p             Print absolute paths in listing and error messages
/q             Suppress info messages
/t[:filename]  List label table
/u             Warn of unused labels
`);
		return xasm.exitCode;
	}
	try {
		xasm.assemblyPass();
		xasm.pass2 = true;
		xasm.assemblyPass();
		if (xasm.getOption('t') && xasm.labelTable.length > 0)
			xasm.listLabelTable();
	} catch (AssemblyError e) {
		xasm.warning(e.msg, true);
		xasm.exitCode = 2;
	}
	xasm.listingStream.close();
	xasm.objectStream.close();
	if (xasm.exitCode <= 1) {
		if (!xasm.getOption('q')) {
			writefln("%d lines of source assembled", xasm.totalLines);
			if (xasm.objectBytes > 0)
				writefln("%d bytes written to the object file", xasm.objectBytes);
		}
		if (xasm.getOption('m')) {
			writef("%s:", xasm.makeTarget);
			foreach (filename; xasm.makeSources)
				writef(" %s", xasm.makeEscape(filename));
			write("\n\txasm");
			for (int i = 1; i < args.length; i++) {
				string arg = args[i];
				if (isOption(arg)) {
					char letter = arg[1];
					if (letter >= 'A' && letter <= 'Z')
						letter += 'a' - 'A';
					switch (letter) {
					case 'm':
						break;
					case 'o':
						if (arg[0] == '/')
							writef(" /%c:$@", arg[1]);
						else {
							writef(" -%c $@", arg[1]);
							++i;
						}
						break;
					default:
						if (arg[0] == '-'
						 && (letter == 'd' || letter == 'l' || letter == 't')
						 && i + 1 < args.length && !isOption(args[i + 1])) {
							writef(" %s %s", arg, xasm.makeEscape(args[++i]));
						}
						else {
							writef(" %s", xasm.makeEscape(arg));
						}
						break;
					}
					continue;
				}
				write(" $<");
			}
			writeln();
		}
	}
	return xasm.exitCode;
}

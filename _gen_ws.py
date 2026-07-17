import pathlib

code = chr(39)*3
part1 = """import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/block.dart';
import '../../models/block_type.dart';
import '../../models/command_tree.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/execution_result.dart';
import 'block_widget.dart';
import 'block_style.dart';

typedef OnProgramChanged = void Function(CommandTree tree);
typedef OnExecutionComplete = void Function(ExecutionResult result);
"""
print(part1)
pathlib.Path('lib/src/renderer/block_workspace.dart').write_text(part1, encoding='utf-8')
print('DONE1')

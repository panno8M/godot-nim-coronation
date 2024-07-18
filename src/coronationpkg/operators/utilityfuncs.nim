import cloths

import submodules/[ wordropes, semanticstrings ]

import functions, arguments

import types/json

import std/[ options, sequtils, strutils, strformat ]

proc extract_result(self: JsonUtilityFunction): RenderableResult =
  convertToResult self.return_type

proc specify(arg: RenderableArgument): RenderableArgument =
  if arg.typeSym == TypeSym"Object":
    arg.typeSym = TypeSym.GodotClass
  arg

proc specify(arg: RenderableResult): RenderableResult =
  if arg.typeSym == TypeSym"Object":
    arg.typeSym = TypeSym.GodotClass
  arg

proc extract_args(self: JsonUtilityFunction): seq[RenderableArgument] =
  result = self.arguments.get(@[])
    .mapIt(specify convert it)
  if self.is_vararg:
    result.add specify RenderableArgument(
      variableSym: VariableSym"args",
      info: ParamInfo(isVarargs: true),
      typeSym: TypeSym.Variant,
      default_value: none string)

type UtilityFunction* = object
  key: ProcKey
  container: ContainerKey
  json: JsonUtilityFunction

proc convert*(json: JsonUtilityFunction): UtilityFunction =
  result.key = ProcKey(
    kind: pkProc,
    name: json.name.scan.convert(ProcSym),
    args: json.extract_args(),
    result: specify json.extract_result(),
  )
  result.container = gen_containerKey result.key
  result.json = json

proc weave_container*(utilfunc: UtilityFunction): Cloth =
  &"var {utilfunc.container}: PtrUtilityFunction"

proc weave_loadstmt*(utilfunc: UtilityFunction): Cloth = weave multiline:
  &"proc_name = stringName \"{utilfunc.json.name}\""
  &"{utilfunc.container} = interfaceVariantGetPtrUtilityFunction(getPtr proc_name, {utilfunc.json.hash})"

proc weave_procdef*(utilfunc: UtilityFunction): Cloth =
  weave multiline:
    weave utilfunc.key
    weave cloths.indent:
      if utilfunc.key.args.len != 0:
        let args = utilfunc.key.args.mapIt("getPtr " & $it.name).join(", ")
        &"let args = [{args}]"
      let argsaddr =
        if utilfunc.key.args.len == 0: "nil"
        else: "addr args[0]"
      let resaddr =
        if utilfunc.key.result.typeSym == TypeSym.Void: "nil"
        else: "getPtr result"
      &"{utilfunc.container}({resaddr}, {argsaddr}, {utilfunc.key.args.len})"
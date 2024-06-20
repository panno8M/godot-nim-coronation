import cloths

import submodules/wordropes
import submodules/semanticstrings
import types/json
import utils

import std/strformat
import std/strutils

proc constValue*(t: string; value: string): string =
  case t
  of "Vector2", "Vector3", "Vector4":
    value.multireplace((t, "vector"), ("inf", "Inf"))
  of "Vector2i", "Vector3i", "Vector4i":
    value.replace(t, "vectori")
  else:
    value.replace(t, $constructorName TypeSym t)

proc weave*(constant: JsonConstant; caller: TypeSym): Cloth =
  &"const {caller}_{constant.name.scan.convert(TypeSym)}*: {constant.`type`} = {constValue constant.`type`, constant.value}"

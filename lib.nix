{ lib }:
let
  inherit (lib)
    defaultFunctor
    filterAttrs
    isAttrs
    isFunction
    mkIf
    mkOption
    mkOptionType
    showOption
    types
    ;
  inherit (lib.types)
    path
    submoduleWith
    ;

  # Polyfill functionTo to make sure it has type merging.
  # Remove 2022-12
  functionTo =
    let sample = types.functionTo lib.types.str;
    in
    if sample.functor.wrapped._type or null == "option-type"
    then types.functionTo
    else
      elemType: lib.mkOptionType {
        name = "functionTo";
        description = "function that evaluates to a(n) ${elemType.description}";
        check = lib.isFunction;
        merge = loc: defs:
          fnArgs: (lib.mergeDefinitions (loc ++ [ "[function body]" ]) elemType (map (fn: { inherit (fn) file; value = fn.value fnArgs; }) defs)).mergedValue;
        getSubOptions = prefix: elemType.getSubOptions (prefix ++ [ "[function body]" ]);
        getSubModules = elemType.getSubModules;
        substSubModules = m: functionTo (elemType.substSubModules m);
        functor = (lib.defaultFunctor "functionTo") // { type = functionTo; wrapped = elemType; };
        nestedTypes.elemType = elemType;
      };

  # Polyfill https://github.com/NixOS/nixpkgs/pull/163617
  deferredModuleWith = lib.deferredModuleWith or (
    attrs@{ staticModules ? [ ] }: mkOptionType {
      name = "deferredModule";
      description = "module";
      check = x: isAttrs x || isFunction x || path.check x;
      merge = loc: defs: staticModules ++ map (def: lib.setDefaultModuleLocation "${def.file}, via option ${showOption loc}" def.value) defs;
      inherit (submoduleWith { modules = staticModules; })
        getSubOptions
        getSubModules;
      substSubModules = m: deferredModuleWith (attrs // {
        staticModules = m;
      });
      functor = defaultFunctor "deferredModuleWith" // {
        type = deferredModuleWith;
        payload = {
          inherit staticModules;
        };
        binOp = lhs: rhs: {
          staticModules = lhs.staticModules ++ rhs.staticModules;
        };
      };
    }
  );


  flake-parts-lib = {
    evalFlakeModule =
      { self
      , specialArgs ? { }
      }:
      module:

      lib.evalModules {
        specialArgs = { inherit self flake-parts-lib; inherit (self) inputs; } // specialArgs;
        modules = [ ./all-modules.nix module ];
      };

    mkFlake = args: module:
      # filter away top-level nulls
      filterAttrs (k: v: v != null) (flake-parts-lib.evalFlakeModule args module).config.flake;

    # For extending options in an already declared submodule.
    # Workaround for https://github.com/NixOS/nixpkgs/issues/146882
    mkSubmoduleOptions =
      options:
      mkOption {
        type = types.submoduleWith {
          modules = [{ inherit options; }];
        };
      };

    mkPerSystemType =
      module:
      deferredModuleWith {
        staticModules = [ module ];
      };

    mkPerSystemOption =
      module:
      mkOption {
        type = flake-parts-lib.mkPerSystemType module;
      };

    mkIfNonEmptySet = set: mkIf (set != {}) set;
  };

in
flake-parts-lib

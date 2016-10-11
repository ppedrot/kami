Require Import String.

Local Open Scope string.
Definition procRqValidReg := "procRqValid".
Definition procRqReplaceReg := "procRqReplace".
Definition procRqWaitReg := "procRqWait".
Definition procRqReg := "procRq".
Definition l1MissByState := "l1MissByState".
Definition l1MissByLine := "l1MissByLine".
Definition l1Hit := "l1Hit".
Definition writeback := "writeback".
Definition upgRq := "upgRq".
Definition upgRs := "upgRs".
Definition ld := "ld".
Definition st := "st".
Definition drop := "drop".
Definition pProcess := "pProcess".

Definition cRqValidReg := "cRqValid".
Definition cRqDirwReg := "cRqDirw".
Definition cRqReg := "cRqReg".
Definition missByState := "missByState".
Definition dwnRq := "dwnRq".
Definition dwnRs_wait := "dwnRs_wait".
Definition dwnRs_noWait := "dwnRs_noWait".
Definition deferred := "deferred".

Definition rqFromProc := "rqFromProc".
Definition rsToProc := "rsToProc".
Definition rqToParent := "rqToParent".
Definition rsToParent := "rsToParent".
Definition rqFromChild := "rqFromChild".
Definition rsFromChild := "rsFromChild".
Definition fromParent := "fromParent".
Definition toChild := "toChild".
Definition line := "line".
Definition tag := "tag".
Definition cs := "cs".
Definition mcs := "mcs".
Definition mline := "mline".

Definition elt := "elt".
Definition enqName := "enq".
Definition deqName := "deq".
Definition enqP := "enqP".
Definition deqP := "deqP".
Definition empty := "empty".
Definition full := "full".
Definition firstEltName := "firstElt".

Definition addr := "addr".
Definition data := "data".
Definition dataArray := "dataArray".
Definition read := "read".
Definition write := "write".

Definition rqFromCToPRule := "rqFromCToP".
Definition rsFromCToPRule := "rsFromCToP".
Definition fromPToCRule := "fromPToC".

Close Scope string.
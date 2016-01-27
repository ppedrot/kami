Require Import Bool List String.
Require Import Lib.CommonTactics Lib.Struct Lib.StringBound Lib.ilist Lib.Word Lib.FMap.
Require Import Syntax Semantics Wf Equiv Inline InlineFacts_1.

Require Import FunctionalExtensionality.

(* NOTE: inlining should be targeted only for basic modules *)
Definition BasicMod (m: Modules) :=
  match m with
    | Mod _ _ _ => True
    | _ => False
  end.

Lemma inlineDmToMod_correct_UnitStep_1:
  forall m (Hm: BasicMod m) (Hequiv: ModEquiv typeUT type m)
         (Hdms: NoDup (namesOf (getDmsBodies m))) dm or u l,
    UnitStep m or u l ->
    M.find dm (dms l) = M.find dm (cms l) ->
    UnitStep (inlineDmToMod m dm) or u (hideMeth l dm m).
Proof.
  induction 4; intros; simpl in *.

  - unfold inlineDmToMod, hideMeth; simpl.
    destruct (getAttribute dm meths); try destruct (noCallDm a a);
    constructor; auto.

  - unfold inlineDmToMod, hideMeth; simpl.
    remember (getAttribute dm meths) as odm; destruct odm; [|eapply SingleRule; eauto].
    remember (noCallDm a a) as ocall; destruct ocall; [|eapply SingleRule; eauto].
    pose proof (getAttribute_Some_name _ _ Heqodm); subst.

    apply SingleRule with
    (ruleBody:= attrType (inlineDmToRule (ruleName :: ruleBody)%struct a))
      (retV:= retV); auto.
    + apply in_map with (f:= fun r => inlineDmToRule r a) in i.
      assumption.
    + simpl; rewrite M.find_empty in H.
      destruct a; apply inlineDm_SemAction_intact; auto.

  - destruct Hequiv.
    pose proof (MethsEquiv_in _ H1 i).

    unfold inlineDmToMod, hideMeth; simpl.
    remember (getAttribute dm meths) as odm; destruct odm; [|eapply SingleMeth; eauto].
    remember (noCallDm a a) as ocall; destruct ocall; [|eapply SingleMeth; eauto].
    destruct a as [an ab]; simpl in *.
    pose proof (getAttribute_Some_name _ _ Heqodm); subst dm.

    destruct (string_dec an meth).
    + subst; exfalso.
      destruct meth as [mn mb]; simpl in *; subst.
      rewrite M.find_add_1 in H.
      assert (ab = mb); subst.
      { rewrite <-(in_NoDup_getAttribute _ _ _ i Hdms) in Heqodm.
        inv Heqodm; reflexivity.
      }
      erewrite noCallDm_SemAction_calls in H; eauto.
      discriminate.
    + subst.
      rewrite M.find_add_2 by assumption.
      rewrite M.find_empty.
      apply SingleMeth with (meth:= inlineDmToDm meth (an :: ab)%struct)
                              (argV:= argV) (retV:= retV); auto.
      * apply in_map with (f:= fun dm => inlineDmToDm dm (an :: ab)%struct) in i.
        assumption.
      * simpl.
        rewrite M.find_add_2 in H by assumption.
        rewrite M.find_empty in H.
        apply inlineDm_SemAction_intact; auto.

  - exfalso; auto.
  - exfalso; auto.

    Grab Existential Variables.
    exact nil.
Qed.

Lemma inlineDmToMod_correct_UnitStep_2:
  forall m or u1 u2 cm1 (meth: DefMethT) argV retV l2,
    UnitStep m or u2 l2 ->
    forall regs rules dms,
      m = Mod regs rules dms ->
      WfModules type m ->
      forall rm2 dm2 cm2,
        l2 = {| ruleMeth := rm2; dms := dm2; cms := cm2 |} ->
        SemAction or (objVal (attrType meth) type argV) u1 cm1 retV ->
        M.Disj u1 u2 -> M.Disj cm1 cm2 ->
        M.Disj (M.add meth
                      {| objType := objType (attrType meth);
                         objVal := (argV, retV) |}
                      (M.empty _)) dm2 ->
        Some {| objType := objType (attrType meth);
                objVal := (argV, retV) |} = M.find meth cm2 ->
        UnitStep (Mod regs (inlineDmToRules rules meth)
                      (inlineDmToDms dms meth))
                 or (M.union u1 u2)
                 {| ruleMeth := rm2;
                    dms := dm2;
                    cms := M.union cm1 (M.remove meth cm2) |}.
Proof.
  induction 1; intros; subst.

  - inv H1; exfalso.
    rewrite M.find_empty in H6; inv H6.

  - inv H; inv H1.
    apply SingleRule with
    (ruleBody:= attrType (inlineDmToRule (ruleName :: ruleBody)%struct meth))
      (retV:= retV0); auto.
    + apply in_map with (f:= fun r => inlineDmToRule r meth) in i.
      assumption.
    + simpl; eapply inlineDm_correct_SemAction; eauto.
      inv H0; eapply wfRules_rule; eauto.
      
  - inv H; inv H1.
    apply SingleMeth with (meth:= inlineDmToDm meth0 meth)
                            (argV:= argV0) (retV:= retV0); auto.
    * apply in_map with (f:= fun dm => inlineDmToDm dm meth) in i.
      assumption.
    * simpl; eapply inlineDm_correct_SemAction; eauto.
      inv H0; eapply wfDms_dms; eauto.

  - inv H.
  - inv H.
Qed.

Lemma inlineDmToRules_UnitStep_intact:
  forall m or u l (a: DefMethT),
    UnitStep m or u l ->
    forall regs rules dms,
      m = Mod regs rules dms ->
      forall rm dm cm,
        l = {| ruleMeth := rm; dms := dm; cms := cm |} ->
        M.find a cm = None ->
        UnitStep (Mod regs (inlineDmToRules rules a) dms) or u
                 {| ruleMeth := rm; dms := dm; cms := cm |}.
Proof.
  induction 1; intros; subst.

  - inv H; inv H0; constructor; auto.
  - inv H; inv H0.
    apply SingleRule with
    (ruleBody:= attrType (inlineDmToRule (ruleName :: ruleBody)%struct a))
      (retV:= retV); auto.
    + apply in_map with (f:= fun r => inlineDmToRule r a) in i.
      assumption.
    + simpl; destruct a; apply inlineDm_SemAction_intact; auto.
  - inv H; inv H0; eapply SingleMeth; eauto.
  - inv H.
  - inv H.
Qed.

Lemma inlineDmToRules_UnitSteps_intact:
  forall regs rules dms or u l (a: DefMethT),
    UnitSteps (Mod regs rules dms) or u l ->
    forall rm dm cm,
      l = {| ruleMeth := rm; dms := dm; cms := cm |} ->
      M.find a cm = None ->
      UnitSteps (Mod regs (inlineDmToRules rules a) dms) or u
                {| ruleMeth := rm; dms := dm; cms := cm |}.
Proof.
  induction 1; intros; subst.

  - apply UnitSteps1.
    eapply inlineDmToRules_UnitStep_intact; eauto.

  - destruct l1 as [rm1 dm1 cm1], l2 as [rm2 dm2 cm2].
    simpl in *; inv H.
    specialize (IHX1 _ _ _ eq_refl).
    specialize (IHX2 _ _ _ eq_refl).
    rewrite M.find_union in H0.
    destruct (M.find a cm1); [discriminate|].
    destruct (M.find a cm2); [discriminate|].
    apply (UnitStepsUnion (IHX1 eq_refl) (IHX2 eq_refl) c).
Qed.

Lemma inlineDmToDms_UnitStep_intact:
  forall m or u l (a: DefMethT),
    UnitStep m or u l ->
    forall regs rules dms,
      m = Mod regs rules dms ->
      forall rm dm cm,
        l = {| ruleMeth := rm; dms := dm; cms := cm |} ->
        M.find a cm = None ->
        UnitStep (Mod regs rules (inlineDmToDms dms a)) or u
                 {| ruleMeth := rm; dms := dm; cms := cm |}.
Proof.
  induction 1; intros; subst.

  - inv H; inv H0; constructor; auto.
  - inv H; inv H0; eapply SingleRule; eauto.
  - inv H; inv H0.
    apply SingleMeth with
    (meth:= inlineDmToDm meth a) (argV:= argV) (retV:= retV); auto.
    + apply in_map with (f:= fun dm => inlineDmToDm dm a) in i.
      assumption.
    + simpl; destruct a; eapply inlineDm_SemAction_intact; auto.
  - inv H.
  - inv H.
Qed.

Lemma inlineDmToDms_UnitSteps_intact:
  forall regs rules dms or u l (a: DefMethT),
    WfModules type (Mod regs rules dms) ->
    UnitSteps (Mod regs rules dms) or u l ->
    forall rm dm cm,
      l = {| ruleMeth := rm; dms := dm; cms := cm |} ->
      M.find a cm = None ->
      UnitSteps (Mod regs rules (inlineDmToDms dms a)) or u
                {| ruleMeth := rm; dms := dm; cms := cm |}.
Proof.
  induction 2; intros; subst.

  - apply UnitSteps1.
    eapply inlineDmToDms_UnitStep_intact; eauto.

  - destruct l1 as [rm1 dm1 cm1], l2 as [rm2 dm2 cm2].
    simpl in *; inv H0.
    specialize (IHX1 _ _ _ eq_refl).
    specialize (IHX2 _ _ _ eq_refl).
    rewrite M.find_union in H1.
    destruct (M.find a cm1); [discriminate|].
    destruct (M.find a cm2); [discriminate|].
    apply (UnitStepsUnion (IHX1 eq_refl) (IHX2 eq_refl) c).
Qed.

Lemma inlineDmToMod_correct_UnitSteps_meth:
  forall regs rules dms or u1 u2 cm1 (meth: DefMethT) argV retV l2,
    WfModules type (Mod regs rules dms) ->
    UnitSteps (Mod regs rules dms) or u2 l2 ->
    forall rm2 dm2 cm2,
      l2 = {| ruleMeth := rm2; dms := dm2; cms := cm2 |} ->
      SemAction or (objVal (attrType meth) type argV) u1 cm1 retV ->
      M.Disj u1 u2 -> M.Disj cm1 cm2 ->
      M.Disj (M.add meth
                    {| objType := objType (attrType meth);
                       objVal := (argV, retV) |}
                    (M.empty _)) dm2 ->
      Some {| objType := objType (attrType meth);
              objVal := (argV, retV) |} = M.find meth cm2 ->
      UnitSteps (Mod regs (inlineDmToRules rules meth)
                     (inlineDmToDms dms meth))
                or (M.union u1 u2)
                {| ruleMeth := rm2;
                   dms := dm2;
                   cms := M.union cm1 (M.remove meth cm2) |}.
Proof.
  induction 2; intros; subst.

  - apply UnitSteps1.
    eapply inlineDmToMod_correct_UnitStep_2; eauto.

  - destruct l1 as [rml dml cml], l2 as [rmr dmr cmr]; simpl in *.
    inv H0.
    specialize (IHX1 _ _ _ eq_refl H1 (M.Disj_union_1 H2)
                     (M.Disj_union_1 H3) (M.Disj_union_1 H4)).
    specialize (IHX2 _ _ _ eq_refl H1 (M.Disj_union_2 H2)
                     (M.Disj_union_2 H3) (M.Disj_union_2 H4)).
    rewrite M.find_union in H5.
    
    remember (M.find meth cml) as ocml; destruct ocml.

    + remember (M.find meth cmr) as ocmr; destruct ocmr;
      [exfalso; inv c; dest; simpl in *;
       eapply M.Disj_find_union_3; eauto|].

      specialize (IHX1 H5).
      match goal with
        | [ |- UnitSteps _ _ ?u {| cms := ?c |} ] =>
          replace u with (M.union (M.union u1 u0) u2)
            by admit; (* map stuff *)
            replace c with (M.union
                              (M.union cm1 (M.remove meth cml))
                              cmr)
            by admit (* map stuff *)
      end.

      match goal with
        | [ |- UnitSteps _ _ _ ?l ] =>
          replace l with
          (mergeLabel
             {| ruleMeth:= rml;
                dms:= dml;
                cms:= M.union cm1 (M.remove meth cml) |}
             {| ruleMeth:= rmr;
                dms:= dmr;
                cms:= cmr |}
          ) by reflexivity
      end.
      apply UnitStepsUnion; auto.
      * eapply inlineDmToRules_UnitSteps_intact; eauto.
        eapply inlineDmToDms_UnitSteps_intact; eauto.
      * admit. (* CanCombine / map stuff *)

    + remember (M.find meth cmr) as ocmr;
      destruct ocmr; [|discriminate].

      specialize (IHX2 H5).
      match goal with
        | [ |- UnitSteps _ _ ?u {| cms := ?c |} ] =>
          replace u with (M.union u0 (M.union u1 u2))
            by admit; (* map stuff *)
            replace c with (M.union
                              cml
                              (M.union cm1 (M.remove meth cmr)))
            by admit (* map stuff *)
      end.

      match goal with
        | [ |- UnitSteps _ _ _ ?l ] =>
          replace l with
          (mergeLabel
             {| ruleMeth:= rml;
                dms:= dml;
                cms:= cml |}
             {| ruleMeth:= rmr;
                dms:= dmr;
                cms:= M.union cm1 (M.remove meth cmr) |}
          ) by reflexivity
      end.
      apply UnitStepsUnion; auto.
      * eapply inlineDmToRules_UnitSteps_intact; eauto.
        eapply inlineDmToDms_UnitSteps_intact; eauto.
      * admit. (* CanCombine / map stuff *)
Qed.

Lemma inlineDmToMod_correct_UnitSteps_sub:
  forall regs rules dms (Hdms: NoDup (namesOf dms))
         or u1 u2 l1 l2 dm,
    In dm dms ->
    WfModules type (Mod regs rules dms) ->
    UnitSteps (Mod regs rules dms) or u2 l2 ->
    UnitSteps (Mod regs rules dms) or u1 l1 ->
    forall rm1 rm2 dm1 dm2 cm1 cm2 t,
      l1 = {| ruleMeth := rm1; dms := dm1; cms := cm1 |} ->
      l2 = {| ruleMeth := rm2; dms := dm2; cms := cm2 |} ->
      M.Disj u1 u2 -> NotBothRule rm1 rm2 ->
      M.Disj dm1 dm2 -> M.Disj cm1 cm2 ->
      Some t = M.find dm dm1 -> Some t = M.find dm cm2 ->
      UnitSteps (Mod regs (inlineDmToRules rules dm)
                     (inlineDmToDms dms dm)) or (M.union u1 u2)
                {| ruleMeth := match rm1 with
                                 | Some r => Some r
                                 | None => rm2
                               end;
                   dms := M.remove dm (M.union dm1 dm2);
                   cms := M.remove dm (M.union cm1 cm2) |}.
Proof.
  induction 5; intros; subst.

  - inv u0; try (rewrite M.find_empty in H7; inv H7; fail).
    destruct (string_dec dm meth);
      [|rewrite M.find_add_2 in H7 by assumption;
         rewrite M.find_empty in H7; inv H7].
    assert (dm = meth) by admit. (* NoDup property *)
    subst; clear e.
    
    rewrite M.find_add_1 in H7 by assumption; inv H7.

    match goal with
      | [ |- UnitSteps _ _ _ {| dms := ?d; cms := ?c |} ] =>
        (* stupid map stuffs *)
        replace d with dm2 by admit;
          replace c with (M.union cm1 (M.remove meth cm2)) by admit
    end.

    eapply inlineDmToMod_correct_UnitSteps_meth; eauto.

  - destruct l0 as [rml dml cml], l1 as [rmr dmr cmr]; simpl in *.
    inv H1; rewrite M.find_union in H7.
    remember (M.find dm dmr) as odmr; destruct odmr.

    + inv H7; clear IHX0_2.
      remember (M.find dm dml) as odml; destruct odml;
      [exfalso; inv c; dest; simpl in *;
       eapply M.Disj_find_union_3 with (m1:= dmr) (m2:= dml);
       eauto|].
      admit. (* induction case: after UnitSteps semantics are changed *)

    + clear IHX0_1.
      admit. (* induction case: after UnitSteps semantics are changed *)
Qed.

Lemma inlineDmToMod_correct_UnitSteps:
  forall m (Hm: BasicMod m) (Hwf: WfModules type m)
         (Hequiv: ModEquiv typeUT type m)
         or nr l dm,
    NoDup (namesOf (getDmsBodies m)) ->
    UnitSteps m or nr l ->
    M.find dm (dms l) = M.find dm (cms l) ->
    UnitSteps (inlineDmToMod m dm) or nr (hideMeth l dm m).
Proof.
  induction 5; intros;
  [constructor; apply inlineDmToMod_correct_UnitStep_1; auto|].

  destruct l1 as [rm1 dm1 cm1], l2 as [rm2 dm2 cm2]; simpl in *.
  remember (M.find dm (M.union dm1 dm2)) as odmv.
  destruct odmv.

  - unfold inlineDmToMod, hideMeth in *; simpl in *.
    rewrite <-Heqodmv, <-H0; simpl.
    destruct (signIsEq t t); [clear e|elim n; auto].

    remember (getAttribute dm (getDmsBodies m)) as odm; destruct odm;
    [|apply (UnitStepsUnion X1 X2 c)].
    remember (noCallDm a a) as oc; destruct oc;
    [|apply (UnitStepsUnion X1 X2 c)].

    pose proof (getAttribute_Some_name _ _ Heqodm); subst.
    destruct m as [regs rules dms|]; [|exfalso; inv Hm].

    unfold CanCombine in c; dest; simpl in *.
    rewrite M.find_union in Heqodmv; rewrite M.find_union in H0.
    remember (M.find a dm1) as odmv1; destruct odmv1.
    
    + inv Heqodmv.
      remember (M.find a cm1) as ocmv1; destruct ocmv1.
      * (* left-side inlined *)
        inv H0; specialize (IHX1 eq_refl).
        destruct (signIsEq t t); [clear e|elim n; auto].

        do 2 rewrite M.remove_union.
        match goal with
          | [ |- UnitSteps _ _ _ ?l ] =>
            replace l with
            (mergeLabel {| ruleMeth:= rm1;
                           dms:= M.remove a dm1;
                           cms:= M.remove a cm1 |}
                        {| ruleMeth:= rm2;
                           dms:= M.remove a dm2;
                           cms:= M.remove a cm2 |})
              by reflexivity
        end.
        apply UnitStepsUnion; auto.
        { assert (M.find a dm2 = None)
            by (destruct (M.Disj_find_None a H3); auto;
                rewrite H0 in Heqodmv1; inv Heqodmv1).
          assert (M.find a cm2 = None)
            by (destruct (M.Disj_find_None a H4); auto;
                rewrite H5 in Heqocmv1; inv Heqocmv1).
          do 2 rewrite M.remove_find_None by assumption.
          eapply inlineDmToRules_UnitSteps_intact; eauto.
          eapply inlineDmToDms_UnitSteps_intact; eauto.
        }
        { repeat split; simpl; auto.
          { apply M.Disj_remove_1, M.Disj_remove_2; assumption. }
          { apply M.Disj_remove_1, M.Disj_remove_2; assumption. }
        }

      * pose proof (getAttribute_Some_body _ _ Heqodm).
        eapply inlineDmToMod_correct_UnitSteps_sub; eauto.

    + remember (M.find a cm1) as ocmv1; destruct ocmv1.
      * clear IHX1 IHX2; inv H0.
        replace (M.union u1 u2) with (M.union u2 u1)
          by (apply M.union_comm; apply M.Disj_comm; auto).
        replace (match rm1 with | Some r => Some r | None => rm2 end) with
        (match rm2 with | Some r => Some r | None => rm1 end)
          by (destruct rm1, rm2; intuition idtac; destruct H2; discriminate).
        replace (M.union dm1 dm2) with (M.union dm2 dm1)
          by (apply M.union_comm; apply M.Disj_comm; auto).
        replace (M.union cm1 cm2) with (M.union cm2 cm1)
          by (apply M.union_comm; apply M.Disj_comm; auto).
        pose proof (getAttribute_Some_body _ _ Heqodm).
        eapply inlineDmToMod_correct_UnitSteps_sub; eauto;
        try (apply M.Disj_comm; auto).
        destruct H2; unfold NotBothRule; intuition auto.
      * (* right-side inlined *)
        rewrite <-Heqodmv, <-H0 in IHX2.
        specialize (IHX2 eq_refl).
        destruct (signIsEq t t); [clear e|elim n; auto].

        do 2 rewrite M.remove_union.
        match goal with
          | [ |- UnitSteps _ _ _ ?l ] =>
            replace l with
            (mergeLabel {| ruleMeth:= rm1;
                           dms:= M.remove a dm1;
                           cms:= M.remove a cm1 |}
                        {| ruleMeth:= rm2;
                           dms:= M.remove a dm2;
                           cms:= M.remove a cm2 |})
              by reflexivity
        end.
        apply UnitStepsUnion; auto.
        { do 2 rewrite M.remove_find_None by auto.
          eapply inlineDmToRules_UnitSteps_intact; eauto.
          eapply inlineDmToDms_UnitSteps_intact; eauto.
        }
        { repeat split; simpl; auto.
          { apply M.Disj_remove_1, M.Disj_remove_2; assumption. }
          { apply M.Disj_remove_1, M.Disj_remove_2; assumption. }
        }

  - unfold hideMeth in *; simpl in *; rewrite <-Heqodmv.
    rewrite M.find_union in Heqodmv.
    destruct (M.find dm dm1); [discriminate|].
    destruct (M.find dm dm2); [discriminate|].
    rewrite M.find_union in H0.
    destruct (M.find dm cm1); [discriminate|].
    destruct (M.find dm cm2); [discriminate|].
    specialize (IHX1 eq_refl); specialize (IHX2 eq_refl).

    destruct (getAttribute dm (getDmsBodies m));
      try destruct (noCallDm a a);
      apply (UnitStepsUnion IHX1 IHX2 c).
Qed.

Lemma inlineDmToMod_wellHidden:
  forall {A} (l: LabelTP A) m a,
    wellHidden l m ->
    wellHidden l (inlineDmToMod m a).
Proof.
  admit. (* TODO: inlining proof *)
Qed.

Lemma wellHidden_find:
  forall {A} m a (l: LabelTP A),
    In a (namesOf (getDmsBodies m)) ->
    wellHidden (hide l) m ->
    M.find a (dms l) = M.find a (cms l).
Proof.
  unfold wellHidden, hide; intros.
  destruct l as [rm dm cm]; simpl in *.
  admit. (* map stuff *)
Qed.

Lemma inlineDmToMod_basicMod:
  forall m a,
    BasicMod m ->
    BasicMod (inlineDmToMod m a).
Proof.
  destruct m; intros; unfold inlineDmToMod;
  destruct (getAttribute _ _); try destruct (noCallDm a0 a0);
  auto.
Qed.

Lemma inlineDmToMod_dms_names:
  forall m a,
    namesOf (getDmsBodies (inlineDmToMod m a)) =
    namesOf (getDmsBodies m).
Proof.
  destruct m; intros; simpl in *.
  - unfold inlineDmToMod.
    destruct (getAttribute _ _); try destruct (noCallDm _ _);
    try (reflexivity; fail).
    simpl; clear.

    induction dms; auto.
    simpl; f_equal; auto.

  - unfold inlineDmToMod.
    destruct (getAttribute _ _); try destruct (noCallDm _ _);
    reflexivity.
Qed.

Lemma inlineDms'_correct_UnitSteps:
  forall cdms m (Hm: BasicMod m) (Hwf: WfModules type m)
         (Hequiv: ModEquiv typeUT type m)
         (Hdms: NoDup (namesOf (getDmsBodies m)))
         (Hcdms: SubList cdms (namesOf (getDmsBodies m)))
         or nr l,
    UnitSteps m or nr l ->
    wellHidden (hide l) m ->
    UnitSteps (inlineDms' m cdms) or nr (hideMeths l cdms m).
Proof.
  induction cdms; [auto|].
  intros; simpl.

  apply SubList_cons_inv in Hcdms; dest.

  apply IHcdms; auto.
  - apply inlineDmToMod_basicMod; auto.
  - admit. (* TODO: WfModules type (inlineDmToMod m a), should have a checker *)
  - admit. (* TODO: ModEquiv typeUT type (inlineDmToMod m a), provable? *)
  - rewrite inlineDmToMod_dms_names; auto.
  - rewrite inlineDmToMod_dms_names; auto.
  - apply inlineDmToMod_correct_UnitSteps; auto.
    eapply wellHidden_find; eauto.
  - apply inlineDmToMod_wellHidden.
    rewrite hideMeth_preserves_hide; auto.
Qed.

Definition InlinableDm (m: Modules) (dm: string) :=
  match getAttribute dm (getDmsBodies m) with
    | Some dmb =>
      if noCallDm dmb dmb then True else False
    | _ => False
  end.

Inductive Inlinable (m: Modules): list string -> Prop :=
| InlinableNil: Inlinable m nil
| InlinableCons:
    forall dm dms,
      Inlinable (inlineDmToMod m dm) dms ->
      InlinableDm m dm ->
      Inlinable m (dm :: dms).

Definition hideMethF {A} (l: LabelTP A) (dmn: string): LabelTP A :=
  match M.find dmn (dms l), M.find dmn (cms l) with
    | Some v1, Some v2 =>
      match signIsEq v1 v2 with
        | left _ => {| ruleMeth := ruleMeth l;
                       dms := M.remove dmn (dms l);
                       cms := M.remove dmn (cms l) |}
        | _ => l
      end
    | _, _ => l
  end.

Fixpoint hideMethsF {A} (l: LabelTP A) (dms: list string): LabelTP A :=
  match dms with
    | nil => l
    | dm :: dms' => hideMethsF (hideMethF l dm) dms'
  end.

Lemma hideMethsF_hide:
  forall dmsAll {A} (l: LabelTP A),
    M.InDomain (dms l) dmsAll ->
    hideMethsF l dmsAll = hide l.
Proof.
  induction dmsAll; intros.

  - destruct l as [rm dm cm]; simpl in *.
    rewrite (M.InDomain_nil _ H).
    f_equal; auto.
    rewrite M.subtractKV_empty_1; reflexivity.

  - destruct l as [rm dm cm]; simpl in *.
    remember (M.find a dm) as oda; remember (M.find a cm) as oca.
    destruct oda.
    + destruct oca.
      * unfold hideMethF; simpl.
        rewrite <-Heqoda, <-Heqoca.
        destruct (signIsEq t t0).
        { subst; rewrite IHdmsAll.
          { unfold hide; f_equal; auto; apply M.subtractKV_remove;
            rewrite <-Heqoda, <-Heqoca; auto.
          }
          { simpl; apply M.InDomain_remove; auto. }
        }
        { admit. }

      * unfold hideMethF; simpl.
        rewrite <-Heqoda, <-Heqoca.
        admit. (* same as the case where t <> t0 *)

    + unfold hideMethF; simpl.
      rewrite <-Heqoda.
      rewrite IHdmsAll; simpl; [reflexivity|].
      eapply M.InDomain_find_None; eauto.
Qed.

Lemma hideMethsF_UnitSteps_hide:
  forall m or nr l,
    UnitSteps m or nr l ->
    hideMethsF l (namesOf (getDmsBodies m)) = hide l.
Proof.
  intros; apply hideMethsF_hide.
  admit. (* Semantics proof *)
Qed.

Lemma hideMeth_hideMethF:
  forall m dm {A} (l: LabelTP A),
    InlinableDm m dm ->
    hideMeth l dm m = hideMethF l dm.
Proof.
  intros; unfold InlinableDm in H; unfold hideMeth.
  destruct (getAttribute dm (getDmsBodies m)); [|intuition idtac].
  destruct (noCallDm a a); [|intuition idtac].
  reflexivity.
Qed.

Lemma hideMeths_hideMethsF:
  forall m dms,
    Inlinable m dms ->
    forall {A} (l: LabelTP A),
      hideMeths l dms m = hideMethsF l dms.
Proof.
  induction 1; intros; [reflexivity|].
  simpl; rewrite hideMeth_hideMethF; auto.
Qed.

Lemma hideMeths_UnitSteps_hide:
  forall m or nr l,
    UnitSteps m or nr l ->
    Inlinable m (namesOf (getDmsBodies m)) ->
    hideMeths l (namesOf (getDmsBodies m)) m = hide l.
Proof.
  intros.
  rewrite hideMeths_hideMethsF; auto.
  eapply hideMethsF_UnitSteps_hide; eauto.
Qed.

Lemma inlineDms_correct_UnitSteps:
  forall m (Hm: BasicMod m) (Hwf: WfModules type m)
         (Hequiv: ModEquiv typeUT type m)
         (Hdms: NoDup (namesOf (getDmsBodies m))) or nr l,
    UnitSteps m or nr l ->
    Inlinable m (namesOf (getDmsBodies m)) ->
    wellHidden (hide l) m ->
    UnitSteps (inlineDms m) or nr (hide l).
Proof.
  intros.
  erewrite <-hideMeths_UnitSteps_hide; eauto.
  apply inlineDms'_correct_UnitSteps; auto.
  apply SubList_refl.
Qed.

Lemma inlineDms_wellHidden:
  forall {A} (l: LabelTP A) m,
    wellHidden l m ->
    wellHidden l (inlineDms m).
Proof.
  intros; unfold inlineDms.
  remember (namesOf (getDmsBodies m)) as dms; clear Heqdms.
  generalize dependent m; induction dms; intros; [assumption|].
  apply IHdms; auto.
  apply inlineDmToMod_wellHidden; auto.
Qed.

Lemma hide_idempotent:
  forall {A} (l: LabelTP A), hide l = hide (hide l).
Proof.
  admit. (* Semantics proof *)
Qed.

Lemma inlineDms_correct:
  forall m (Hm: BasicMod m) (Hwf: WfModules type m)
         (Hequiv: ModEquiv typeUT type m)
         (Hdms: NoDup (namesOf (getDmsBodies m)))
         (Hin: Inlinable m (namesOf (getDmsBodies m)))
         or nr l,
    Step m or nr l ->
    Step (inlineDms m) or nr l.
Proof.
  induction 6; intros; subst.
  apply MkStep with (l:= hide l); auto.
  - apply inlineDms_correct_UnitSteps; auto.
  - apply hide_idempotent.
  - apply inlineDms_wellHidden; auto.
Qed.

Lemma merge_preserves_step:
  forall m or nr l,
    Step m or nr l ->
    Step (merge m) or nr l.
Proof.
  admit. (* Semantics proof *)
Qed.

(* Lemma filter_preserves_step: *)
(*   forall regs rules dmsAll or nr l filt, *)
(*     Step (Mod regs rules dmsAll) or nr l -> *)
(*     M.NotOnDomain (dms l) filt -> *)
(*     Step (Mod regs rules (filterDms dmsAll filt)) or nr l. *)
(* Proof. *)
(* Qed. *)

(* Instead of filter, use below *)
Lemma step_dms_hidden:
  forall m or nr l,
    Step m or nr l ->
    M.NotOnDomain (dms l) (getCmsMod m).
Proof.
  intros; inv X.
  unfold wellHidden in H0.
  destruct (hide l0); simpl in *; intuition.
Qed.

Theorem inline_correct:
  forall m (Hwf: WfModules type (merge m))
         (Hequiv: ModEquiv typeUT type (merge m))
         (Hdms: NoDup (namesOf (getDmsBodies m)))
         (Hin: Inlinable (merge m) (namesOf (getDmsBodies m)))
         or nr l,
    Step m or nr l ->
    Step (inline m) or nr l.
Proof.
  intros; unfold inline.
  apply inlineDms_correct; auto.
  - unfold BasicMod, merge; auto.
  - apply merge_preserves_step; auto.
Qed.

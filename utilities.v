(**************************************************************************)
(*                                                                        *)
(*     Sniper                                                             *)
(*     Copyright (C) 2021                                                 *)
(*                                                                        *)
(*     See file "AUTHORS" for the list of authors                         *)
(*                                                                        *)
(*   This file is distributed under the terms of the CeCILL-C licence     *)
(*                                                                        *)
(**************************************************************************)


Require Import SMTCoq.SMTCoq.

From MetaCoq Require Import All.
Require Import MetaCoq.Template.All.
Require Import MetaCoq.Template.Universes.
Require Import MetaCoq.PCUIC.PCUICEquality.
Require Import MetaCoq.PCUIC.PCUICSubstitution.
Require Import MetaCoq.Template.All.

MetaCoq Quote Definition unit_reif := unit.

Ltac unquote_term t_reif := 
run_template_program (tmUnquote t_reif) ltac:(fun t => 
let x := constr:(t.(my_projT2)) in let y := eval hnf in x in pose y).


Ltac unquote_list l :=
match constr:(l) with
| nil => idtac
| cons ?x ?xs => unquote_term x ; unquote_list xs
end.

Ltac prove_hypothesis H :=
repeat match goal with
  | H' := ?x : ?P |- _ =>  lazymatch P with 
                | Prop => let def := fresh in assert (def : x) by 
(intros; rewrite H; auto) ;  clear H'
          end
end.


(* [inverse_tactic tactic] succceds when [tactic] fails, and the other way round *)
Ltac inverse_tactic tactic := try (tactic; fail 1).

(* [constr_neq t u] fails if and only if [t] and [u] are convertible *)
Ltac constr_neq t u := inverse_tactic ltac:(constr_eq t u).


Ltac is_not_in_tuple p z := 
lazymatch constr:(p) with
| (?x, ?y) => is_not_in_tuple constr:(x) z ; is_not_in_tuple constr:(y) z
| _ => constr_neq p z 
end.

Ltac unquote_env_aux e := match e with 
| [] => idtac
| ?x :: ?xs => unquote_term x ; unquote_env_aux xs
end.


(* Nothing about inductives for now *)
Fixpoint get_decl (e : global_env) := match e with 
| [] => []
| x :: e' => match (snd x) with
      | ConstantDecl u => match u.(cst_body) with
            | Some v => v :: get_decl e'
            | None => get_decl e'
            end
      | InductiveDecl u => get_decl e'
      end
end.



Ltac unquote_env e := let e' := constr:(fst e) in 
let l := constr:(get_decl e') in let l':= eval compute in l in 
unquote_env_aux l'.

Ltac rec_quote_term t idn := (run_template_program (tmQuoteRec t) ltac:(fun x => (pose  x as idn))).



MetaCoq Quote Definition eq_reif := Eval cbn in @eq.

Ltac notHyp T  :=
repeat match goal with
  | [H : _ |- _] => let U := type of H in constr_eq U T ; fail 2
end.

Definition mkEq (B t1 t2 : term) := tApp eq_reif [B ; t1 ; t2].

Definition mkProd T u :=
tProd {| binder_name := nAnon; binder_relevance := Relevant |} T u.

Definition mkApp t u :=
tApp t [u].

(* A tactic version of if/else *)
Ltac if_else_ltac tac1 tac2 b := lazymatch b with
  | true => tac1
  | false => tac2
end.

(* Check is a MetaCoq term is a sort which is not Prop *)
Definition is_type (t : term) := match t with
                                 | tSort s => negb (Universe.is_prop s)
                                 |_ => false
                                  end.








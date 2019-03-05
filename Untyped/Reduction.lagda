\begin{code}
module Untyped.Reduction where
\end{code}

\begin{code}
open import Untyped.Term
open import Untyped.RenamingSubstitution

open import Data.Nat
open import Data.Product renaming (proj₁ to fst; proj₂ to snd)
open import Data.Sum renaming (inj₁ to inl; inj₂ to inr)
open import Data.Maybe
open import Data.List hiding ([_])
\end{code}

\begin{code}
infix 2 _—→_
\end{code}


\begin{code}
-- for untyped reduction, error also includes thing like impossible
-- applications
data Error {n} : n ⊢ → Set where
  E-error : Error error
\end{code}

\begin{code}
data Value {n} : ∀{n} → n ⊢ → Set where
  V-ƛ : (t : suc n ⊢) → Value (ƛ t)
  V-con : (tcn : TermCon) → Value (con {n} tcn)

data _—→_ {n} : n ⊢ → n ⊢ → Set where
  ξ-· : {L L' : n ⊢}{M : n ⊢} → L —→ L' → L · M —→ L' · M
  E-· : {L : n ⊢}{M : n ⊢} → Error L → L · M —→ error
  E-con : {tcn : TermCon}{L : n ⊢} → con tcn · L —→ error
  β-ƛ : {L : suc n ⊢}{M : n ⊢} → ƛ L · M —→ L [ M ]

  ξ-builtin : {ts : List (n ⊢)}
              (vs : List (Σ (n ⊢) (Value {n})))
              {t t' : n ⊢}
            → t —→ t'
            → (ts' : List (n ⊢))
            → builtin ts —→
                builtin (Data.List.map fst vs ++ Data.List.[ t' ] ++ ts')
  E-builtin : {ts : List (n ⊢)}
              (vs : List (Σ (n ⊢) (Value {n})))
              {t : n ⊢}
            → Error t
            → (ts' : List (n ⊢))
            → builtin ts —→ error
            
open import Data.Unit

\end{code}


\begin{code}
data _—→⋆_ {n} : n ⊢ → n ⊢ → Set where
  refl  : {t : n ⊢} → t —→⋆ t
  trans : {t t' t'' : n ⊢} → t —→ t' → t' —→⋆ t'' → t —→⋆ t''
\end{code}

\begin{code}
data ProgList {n} : Set where
  done : List (Σ (n ⊢) (Value {n})) → ProgList
  step : (vs : List (Σ (n ⊢) (Value {n}))){t t' : n ⊢} → t —→ t' → List (n ⊢)
       → ProgList
  error : (vs : List (Σ (n ⊢) (Value {n}))){t : n ⊢} → Error t → List (n ⊢)
        → ProgList

progress : (t : 0 ⊢) → (Value {0} t ⊎ Error t) ⊎ Σ (0 ⊢) λ t' → t —→ t'
progressList : List (0 ⊢) → ProgList {0}
progressList []       = done []
progressList (t ∷ ts) with progress t
progressList (t ∷ ts) | inl (inl vt) with progressList ts
progressList (t ∷ ts) | inl (inl vt) | done  vs       = done ((t , vt) ∷ vs)
progressList (t ∷ ts) | inl (inl vt) | step  vs p ts' =
  step ((t , vt) ∷ vs) p ts'
progressList (t ∷ ts) | inl (inl vt) | error vs e ts' =
  error ((t , vt) ∷ vs) e ts'
progressList (t ∷ ts) | inl (inr e) = error [] e ts
progressList (t ∷ ts) | inr (t' , p) = step [] p ts

progress (` ())
progress (ƛ t)        = inl (inl (V-ƛ t))
progress (t · u)      with progress t
progress (.(ƛ t) · u)     | inl (inl (V-ƛ t))     = inr (t [ u ] , β-ƛ)
progress (.(con tcn) · u) | inl (inl (V-con tcn)) = inr (error , E-con)
progress (t · u)          | inl (inr e)  = inr (error , E-· e)
progress (t · u)          | inr (t' , p) = inr (t' · u  , ξ-· p)
progress (con tcn)    = inl (inl (V-con tcn))
progress (builtin ts) with progressList ts
progress (builtin ts) | done  vs       = {!!}
progress (builtin ts) | step  vs p ts' = inr (builtin _ , ξ-builtin vs p ts')
progress (builtin ts) | error vs e ts' = inr (error     , E-builtin vs e ts')
progress error        = inl (inr E-error)

\end{code}

\begin{code}
run : (t : 0 ⊢) → ℕ → Σ (0 ⊢) λ t' → t —→⋆ t' × (Maybe (Value t') ⊎ Error t')
run t 0       = t , (refl , inl nothing)
run t (suc n) with progress t
run t (suc n) | inl (inl vt) = t , refl , inl (just vt)
run t (suc n) | inl (inr et) = t , refl , inr et
run t (suc n) | inr (t' , p) with run t' n
run t (suc n) | inr (t' , p) | t'' , q , mvt'' = t'' , trans p q , mvt''
\end{code}

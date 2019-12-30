; RUN: %opt < %s %loadEnzyme -enzyme -enzyme_preopt=false -inline -mem2reg -instcombine -correlated-propagation -adce -instcombine -simplifycfg -early-cse -simplifycfg -S | FileCheck %s

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local void @insertion_sort_inner(float* nocapture %array, i32 %i) local_unnamed_addr #0 {
entry:
  %cmp29 = icmp sgt i32 %i, 0
  br i1 %cmp29, label %land.rhs.preheader, label %while.end

land.rhs.preheader:                               ; preds = %entry
  %0 = sext i32 %i to i64
  br label %land.rhs

land.rhs:                                         ; preds = %land.rhs.preheader, %while.body
  %indvars.iv = phi i64 [ %0, %land.rhs.preheader ], [ %indvars.iv.next, %while.body ]
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  %arrayidx = getelementptr inbounds float, float* %array, i64 %indvars.iv.next
  %1 = load float, float* %arrayidx, align 4
  %arrayidx2 = getelementptr inbounds float, float* %array, i64 %indvars.iv
  %2 = load float, float* %arrayidx2, align 4
  %cmp3 = fcmp ogt float %1, %2
  br i1 %cmp3, label %while.body, label %while.end

while.body:                                       ; preds = %land.rhs
  store float %1, float* %arrayidx2, align 4
  store float %2, float* %arrayidx, align 4
  %cmp = icmp sgt i64 %indvars.iv, 1
  br i1 %cmp, label %land.rhs, label %while.end

while.end:                                        ; preds = %land.rhs, %while.body, %entry
  ret void
}


define dso_local void @dsum(float* %x, float* %xp, i32 %n) {
entry:
  %0 = tail call double (void (float*, i32)*, ...) @__enzyme_autodiff(void (float*, i32)* nonnull @insertion_sort_inner, float* %x, float* %xp, i32 %n)
  ret void
}

declare double @__enzyme_autodiff(void (float*, i32)*, ...)

attributes #0 = { noinline norecurse nounwind uwtable }

; CHECK: define internal {} @diffeinsertion_sort_inner(float* nocapture %array, float* %"array'", i32 %i) local_unnamed_addr #0 {
; CHECK-NEXT: entry:
; CHECK-NEXT:   %cmp29 = icmp sgt i32 %i, 0
; CHECK-NEXT:   br i1 %cmp29, label %land.rhs.preheader, label %invertwhile.end

; CHECK: land.rhs.preheader:                               ; preds = %entry
; CHECK-NEXT:   %0 = sext i32 %i to i64
; CHECK-NEXT:   br label %land.rhs

; CHECK: land.rhs:                                         ; preds = %while.body, %land.rhs.preheader
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %while.body ], [ 0, %land.rhs.preheader ]
; CHECK-NEXT:   %1 = sub i64 %0, %iv
; CHECK-NEXT:   %indvars.iv.next = add nsw i64 %1, -1
; CHECK-NEXT:   %arrayidx = getelementptr inbounds float, float* %array, i64 %indvars.iv.next
; CHECK-NEXT:   %2 = load float, float* %arrayidx, align 4
; CHECK-NEXT:   %arrayidx2 = getelementptr inbounds float, float* %array, i64 %1
; CHECK-NEXT:   %3 = load float, float* %arrayidx2, align 4
; CHECK-NEXT:   %cmp3 = fcmp ogt float %2, %3
; CHECK-NEXT:   br i1 %cmp3, label %while.body, label %invertwhile.end

; CHECK: while.body:                                       ; preds = %land.rhs
; CHECK-NEXT:   %iv.next = add nuw i64 %iv, 1
; CHECK-NEXT:   store float %2, float* %arrayidx2, align 4
; CHECK-NEXT:   store float %3, float* %arrayidx, align 4
; CHECK-NEXT:   %cmp = icmp sgt i64 %1, 1
; CHECK-NEXT:   br i1 %cmp, label %land.rhs, label %invertwhile.end

; CHECK: invertentry:                                      ; preds = %invertland.rhs, %invertwhile.end
; CHECK-NEXT:   ret {} undef

; CHECK: invertland.rhs:                                   ; preds = %invertwhile.end.loopexit, %invertwhile.body
; CHECK-NEXT:   %"'de5.0" = phi float [ %13, %invertwhile.body ], [ 0.000000e+00, %invertwhile.end.loopexit ]
; CHECK-NEXT:   %"'de.0" = phi float [ %12, %invertwhile.body ], [ 0.000000e+00, %invertwhile.end.loopexit ]
; CHECK-NEXT:   %"iv'ac.0" = phi i64 [ %"iv'ac.1", %invertwhile.body ], [ %loopLimit_cache.0, %invertwhile.end.loopexit ]
; CHECK-NEXT:   %_unwrap = sext i32 %i to i64
; CHECK-NEXT:   %_unwrap2 = sub i64 %_unwrap, %"iv'ac.0"
; CHECK-NEXT:   %"arrayidx2'ipg" = getelementptr float, float* %"array'", i64 %_unwrap2
; CHECK-NEXT:   %4 = load float, float* %"arrayidx2'ipg", align 4
; CHECK-NEXT:   %5 = fadd fast float %4, %"'de.0"
; CHECK-NEXT:   store float %5, float* %"arrayidx2'ipg", align 4
; CHECK-NEXT:   %6 = xor i64 %"iv'ac.0", -1
; CHECK-NEXT:   %indvars.iv.next_unwrap = add i64 %6, %_unwrap
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr float, float* %"array'", i64 %indvars.iv.next_unwrap
; CHECK-NEXT:   %7 = load float, float* %"arrayidx'ipg", align 4
; CHECK-NEXT:   %8 = fadd fast float %7, %"'de5.0"
; CHECK-NEXT:   store float %8, float* %"arrayidx'ipg", align 4
; CHECK-NEXT:   %9 = icmp eq i64 %"iv'ac.0", 0
; CHECK-NEXT:   br i1 %9, label %invertentry, label %incinvertland.rhs

; CHECK: incinvertland.rhs:                                ; preds = %invertland.rhs
; CHECK-NEXT:   %10 = add nsw i64 %"iv'ac.0", -1
; CHECK-NEXT:   br label %invertwhile.body

; CHECK: invertwhile.body:                                 ; preds = %invertwhile.end.loopexit, %incinvertland.rhs
; CHECK-NEXT:   %"iv'ac.1" = phi i64 [ %10, %incinvertland.rhs ], [ %loopLimit_cache.0, %invertwhile.end.loopexit ]
; CHECK-NEXT:   %_unwrap6 = sext i32 %i to i64
; CHECK-NEXT:   %11 = xor i64 %"iv'ac.1", -1
; CHECK-NEXT:   %indvars.iv.next_unwrap9 = add i64 %11, %_unwrap6
; CHECK-NEXT:   %"arrayidx'ipg10" = getelementptr float, float* %"array'", i64 %indvars.iv.next_unwrap9
; CHECK-NEXT:   %12 = load float, float* %"arrayidx'ipg10", align 4
; CHECK-NEXT:   store float 0.000000e+00, float* %"arrayidx'ipg10", align 4
; CHECK-NEXT:   %_unwrap16 = sub i64 %_unwrap6, %"iv'ac.1"
; CHECK-NEXT:   %"arrayidx2'ipg17" = getelementptr float, float* %"array'", i64 %_unwrap16
; CHECK-NEXT:   %13 = load float, float* %"arrayidx2'ipg17", align 4
; CHECK-NEXT:   store float 0.000000e+00, float* %"arrayidx2'ipg17", align 4
; CHECK-NEXT:   br label %invertland.rhs

; CHECK: invertwhile.end.loopexit:                         ; preds = %invertwhile.end
; CHECK-NEXT:   br i1 %_cache.0, label %invertwhile.body, label %invertland.rhs

; CHECK: invertwhile.end:                                  ; preds = %entry, %while.body, %land.rhs
; CHECK-NEXT:   %_cache.0 = phi i1 [ undef, %entry ], [ true, %while.body ], [ %cmp3, %land.rhs ]
; CHECK-NEXT:   %loopLimit_cache.0 = phi i64 [ undef, %entry ], [ %iv, %while.body ], [ %iv, %land.rhs ]
; CHECK-NEXT:   br i1 %cmp29, label %invertwhile.end.loopexit, label %invertentry
; CHECK-NEXT: }

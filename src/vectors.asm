%define syscall		int 80h		; call the kernel
%define zeros		0.0, 0.0, 0.0

section .data
	rdotp: dd 0.0,
	rnorm: dd 0.0,
	rnrm3: dd zeros
	rsum3: dd zeros
	rsub3: dd zeros

section .text
	global _dot, _norm, _normalise, _vec_add, _vec_sub

; ecx in: Vec3 *v1
; edx in: Vec3 *v2
; ecx out: float *value (&rdotp)
_dot:
	fld dword [ecx]
	fld dword [edx]
	fmulp
	fstp dword [rdotp]
	fld dword [ecx + 4]
	fld dword [edx + 4]
	fmulp
	fld dword [rdotp]
	faddp
	fstp dword [rdotp]
	fld dword [ecx + 8]
	fld dword [edx + 8]
	fmulp
	fld dword [rdotp]
	faddp
	fstp dword [rdotp]
	mov ecx, rdotp
	ret

; ecx in: Vec3 *vector
; ecx out: float *value (&rnorm)
_norm:
	fld dword [ecx]
	fld dword [ecx]
	fmulp
	fstp dword [rnorm]
	fld dword [ecx + 4]
	fld dword [ecx + 4]
	fmulp
	fld dword [rnorm]
	faddp
	fstp dword [rnorm]
	fld dword [ecx + 8]
	fld dword [ecx + 8]
	fmulp
	fld dword [rnorm]
	faddp
	fsqrt
	fstp dword [rnorm]
	mov ecx, rnorm
	ret

; ecx in: Vec3 *vector
; ecx out: Vec3 *normalised (&rnrm3)
_normalise:
	push ecx
	call _norm
	pop ecx
	fld dword [ecx]			; x component
	fld dword [rnorm]
	fdivp
	fstp dword [rnrm3]
	fld dword [ecx + 4]		; y component
	fld dword [rnorm]
	fdivp
	fstp dword [rnrm3 + 4]
	fld dword [ecx + 8]		; z component
	fld dword [rnorm]
	fdivp
	fstp dword [rnrm3 + 8]
	mov ecx, rnrm3			; return in ecx
	ret

; ecx in: Vec3 *v1
; edx in: Vec3 *v2
; ecx out: Vec3 *sum (&rsum3)
_vec_add:
	fld dword [ecx]
	fld dword [edx]
	faddp
	fstp dword [rsum3]
	fld dword [ecx + 4]
	fld dword [edx + 4]
	faddp
	fstp dword [rsum3 + 4]
	fld dword [ecx + 8]
	fld dword [edx + 8]
	faddp
	fstp dword [rsum3 + 8]
	mov ecx, rsum3
	ret


; ecx in: Vec3 *v1
; edx in: Vec3 *v2
; ecx out: Vec3 *sum (&rsub3)
_vec_sub:
	fld dword [ecx]
	fld dword [edx]
	fsubp
	fstp dword [rsub3]
	fld dword [ecx + 4]
	fld dword [edx + 4]
	fsubp
	fstp dword [rsub3 + 4]
	fld dword [ecx + 8]
	fld dword [edx + 8]
	fsubp
	fstp dword [rsub3 + 8]
	mov ecx, rsub3
	ret

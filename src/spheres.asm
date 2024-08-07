%define syscall		int 80h		; call the kernel

section .data
	b: dd 2.0,
	c: dd 0.0,
	delta: dd -4.0,
	t1: dd 0.0,
	t2: dd 0.0,
	temp: dd 0.0,

section .text
	global _sphere_intersection
	extern _dot, _norm, _vec_sub	; vectors

; stack: (restored on output)
;(+0x00) *ret_location
; +0x04 *center
; +0x08 *radius
; +0x0B *ray_origin
; +0x10 *ray_direction
; ecx out: float *distance
; edx out: is_none
; flags out: eq=1 when none
_sphere_intersection:
	; reset the variables
	mov ecx, __float32__(2.0)
	mov [b], ecx
	mov ecx, __float32__(0.0)
	mov [c], ecx
	mov ecx, __float32__(-4.0)
	mov [delta], ecx
	; calculating b
	mov ecx, esp
	add ecx, 0xB
	mov edx, esp
	add edx, 0x8
	call _vec_sub
	mov edx, esp
	add edx, 0x10
	call _dot
	fld dword [ecx]
	fld dword [b]
	fmulp
	fstp dword [b]
	; calculating c
	mov ecx, esp
	add ecx, 0xB
	mov edx, esp
	add edx, 0x8
	call _vec_sub
	call _norm
	fld dword [ecx]
	fld dword [ecx]
	fmulp
	fstp dword [c]
	fld dword [esp + 0x8]
	fld dword [esp + 0x8]
	fmulp
	fld dword [c]
	fsubrp
	fstp dword [c]
	; calculating delta
	fld dword [delta]
	fld dword [c]
	fmulp
	fstp dword [delta]
	fld dword [b]
	fld dword [b]
	fmulp
	fld dword [delta]
	faddp
	fst dword [delta]
	fldz
	fcomp
	fnstsw ax
	sahf
	jp _is_nan
	ja _greater_than
	jmp _less_than
	; delta > 0
_greater_than:
	fsqrt
	fstp dword [delta] ; delta = sqrt(delta)
	fldz
	fld dword [b]
	fsubp
	fst dword [b] ; b = -b
	fld dword [delta]
	faddp ; -b + sqrt(delta)
	mov ecx, __float32__(2.0)
	mov [temp], ecx
	fld dword [temp]
	fdivp ; / 2
	fstp dword [t1] ; t1 = (-b + sqrt(delta)) / 2
	fld dword [b]
	fld dword [delta]
	fsubp ; -b - delta
	fld dword [temp]
	fdivp
	fst dword [t2] ; t1 = (-b + sqrt(delta)) / 2
	fldz ; t2 > 0 ?
	fcompp
	fnstsw ax
	sahf
	jp _is_nan
	jbe _less_than
	fld dword [t1] ; t1 > 0 ?
	fldz
	fcompp
	fnstsw ax
	sahf
	jp _is_nan
	jbe _less_than
	fld dword [t1] ; t1 > t2 ?
	fld dword [t2]
	fcompp
	fnstsw ax
	sahf
	jp _is_nan
	jb _ret_t1
_ret_t2:
	mov ecx, t2
	xor edx, edx
	cmp edx, 0x1
	jmp _func_end
_ret_t1:
	mov ecx, t2
	xor edx, edx
	cmp edx, 0x1
	jmp _func_end
_is_nan:
_less_than:
	mov edx, 0x1
	cmp edx, 0x1
_func_end:
	pop eax
	pop ebx
	pop ebx
	pop ebx
	pop ebx
	push eax
	ret

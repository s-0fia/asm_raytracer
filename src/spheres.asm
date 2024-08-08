%define syscall		int 80h		; call the kernel
%define sphere_size 0x20 ; spheres are 32 bytes

section .data
	achar: db "d",
	; sphere_intersection vars
	b: dd 2.0,
	c: dd 0.0,
	delta: dd -4.0,
	t1: dd 0.0,
	t2: dd 0.0,
	temp: dd 0.0,
	; nearest_intersected_obj vars
	min_distance: dd 0.0,
	md_is_none: dd 0,
	curr_obj: dd 0,
	end_objs: dd 0,
	closest_obj: dd 0,

section .text
	global _sphere_intersection, _nearest_intersected_obj
	extern _dot, _norm, _vec_sub	; vectors

; stack: (restored on output)
;(+0x00) *ret_location
; +0x04 *center
; +0x08 *radius
; +0x0C *ray_origin
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
	mov ecx, [esp + 0xC]
	mov edx, [esp + 0x4]
	call _vec_sub
	mov edx, [esp + 0x10]
	call _dot
	fld dword [ecx]
	fld dword [b]
	fmulp
	fstp dword [b]
	; calculating c
	mov ecx, [esp + 0xC]
	mov edx, [esp + 0x4]
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
	fcompp ; 0 vs delta
	fnstsw ax
	sahf
	jp _si_is_nan
	jb _si_greater_than ; 0 < delta
	jmp _si_less_than
	; delta > 0
_si_greater_than:
	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, achar
	mov edx, 0x1
	syscall
	fld dword [delta]
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
	fldz
	fst dword [t2] ; t1 = (-b + sqrt(delta)) / 2
	fcompp ; t2 > 0 ?
	fnstsw ax
	sahf
	jp _si_is_nan
	jbe _si_less_than
	fldz
	fld dword [t1]
	fcompp ; t1 > 0 ?
	fnstsw ax
	sahf
	jp _si_is_nan
	jbe _si_less_than
	fld dword [t1]
	fld dword [t2]
	fcompp ; t2 vs t1 ?
	fnstsw ax
	sahf
	jp _si_is_nan
	ja _si_ret_t1
_si_ret_t2:
	mov ecx, t2
	xor edx, edx
	cmp edx, 0x1
	jmp _si_func_end
_si_ret_t1:
	mov ecx, t2
	xor edx, edx
	cmp edx, 0x1
	jmp _si_func_end
_si_is_nan:
_si_less_than:
	mov edx, 0x1
	cmp edx, 0x1
_si_func_end:
	pop eax
	pop ebx
	pop ebx
	pop ebx
	pop ebx
	push eax
	ret

; stack: (restored on output)
;(+0x00) *ret_location
; +0x04 *objs
; +0x08 num_of_objs
; +0x0C *ray_origin
; +0x10 *ray_direction
; eax out: is_none
; ecx out: float *min_distance (&min_disance)
; edx out: Sphere *nearest_obj
; flags out: eq=1 when none
_nearest_intersected_obj:
	; reset variables
	mov ecx, 0x1
	mov [md_is_none], ecx ; set it to none
	fldz
	fstp dword [min_distance] ; set distance to 0.0
	mov eax, [esp + 0x8]
	mov ebx, sphere_size
	xor edx, edx
	mul ebx
	mov ecx, [esp + 0x4] ; ecx *start
	add eax, ecx
	mov [curr_obj], ecx ; *start
	mov [end_objs], eax ; *end
_nio_for_objs:
	mov ecx, [curr_obj]
	mov edx, [end_objs]
	cmp ecx, edx
	jae _nio_for_done ; if *start >= *end
	push dword [esp + 0x10] ; *ray_direction
	push dword [esp + 0x10] ; *ray_origin
	mov eax, [curr_obj]
	mov ecx, eax
	mov ebx, 0xC
	add eax, ebx
	push eax ; *radius
	push ecx ; *center
	call _sphere_intersection
	; ecx: float *distance
	; flags: eq=IS_NONE
	jne _nio_distance_is_some
_nio_distance_is_none:
	jmp _nio_for_continue
_nio_distance_is_some:
	mov eax, [md_is_none]
	cmp eax, 0x1
	je _nio_set_dist_and_obj
	fld dword [min_distance]
	fld dword [ecx]
	fcompp ; distance vs min_distance
	fnstsw ax
	sahf
	jp _nio_for_continue ; is NaN
	jb _nio_set_dist_and_obj
	jmp _nio_for_continue
_nio_set_dist_and_obj:
	fld dword [ecx] ; load distance
	fstp dword [min_distance] ; put to md
	mov eax, 0x0
	mov [md_is_none], eax
	mov eax, [curr_obj]
	mov [closest_obj], eax
_nio_for_continue:
	mov ecx, [curr_obj]
	mov ebx, sphere_size
	add ecx, ebx
	mov [curr_obj], ecx
	jmp _nio_for_objs
_nio_for_done:
	pop ecx
	pop edx
	pop edx
	pop edx
	pop edx
	push ecx
	mov eax, [md_is_none]
	cmp eax, 0x1
	mov ecx, min_distance
	mov edx, closest_obj
	ret
; eax out: is_none
; ecx out: float *min_distance (&min_disance)
; edx out: Sphere *nearest_obj
; flags out: eq=1 when none

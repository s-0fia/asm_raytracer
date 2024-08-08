%define syscall		int 80h		; call the kernel

%macro stringln 2		; Macro to make string declarations easier
	%1: db %2, 0xA
	%1_len: equ $-%1
%endmacro
%macro string 2		; Macro to make string declarations easier
	%1: db %2
	%1_len: equ $-%1
%endmacro
%macro buffer 2
	%1: times %2 db 0
	%1_len: equ $-%1
%endmacro

%macro sphere 9
	%1:	dd %2, %3, %4
	%1_radius:		dd %5
	%1_ambient:		dd %6
	%1_diffuse:		dd %7
	%1_specular:	dd %8
	%1_shininess:	dd %9
%endmacro
%define sphere_size 0x20 ; spheres are 32 bytes
%define new_vec3 dd 0.0, 0.0, 0.0

section .data
	achar: db "a",
	newln: db 0xA,
	idx: dw 0x0
	bright_num: dw 0x9,
	string brightness, " .:-=+*#%@"
	num_of_spheres: dd 0x2,
				   ; x    y    z   rad   amb  dif  spc  shi
	sphere spheres,-0.2, 0.0,-1.0, 0.7,  0.1, 0.7, 1.0, 100.0
				   ; x    y    z   rad   amb  dif  spc  shi
	sphere sphere1, 0.0, 9.e3,0.0,8999.3,0.1, 0.6, 1.0, 100.0
				   ; x    y    z   rad   amb  dif  spc  shi
	sphere light,   5.0, 5.0, 5.0, 0.0,  1.0,1.0, 1.0, 0.0
	camera: new_vec3
	temp: dd 0.0,
	width: dw 75,
	height: dw 70,
	ratio: dd 0.0,
	x: dd 0.0,
	x_step: dd 0.0,
	y: dd 0.0,
	y_step: dd 0.0,
	colour: dd 0.25,
	closest_obj: dd 0,
	min_distance: dd 0,
	pixel: new_vec3
	dir: new_vec3
	intersection: new_vec3
	surface_normal: new_vec3
	shifted_point: new_vec3
	intersection_to_light: new_vec3
	light_distance: dd 0.0
	intersection_to_camera: new_vec3
	h: new_vec3

section .text
	global _start
	extern _parse_num, _print_num, _put_char				; std
	extern _dot, _norm, _normalise, _vec_add, _vec_sub		; vectors
	extern _sphere_intersection, _nearest_intersected_obj	; spheres

_start:
	pop ecx ; ETX char
	pop ecx ; path
	pop ecx ; width or null
	cmp ecx, 0x0
	je _setup
	mov edx, 4
	call _parse_num
	mov ebx, 0x2
	sub eax, ebx
	xor edx, edx
	div ebx
	mov [width], eax

	pop ecx ; height or null
	cmp ecx, 0x0
	je _setup
	mov edx, 4
	call _parse_num

	mov ebx, 0xA
	sub eax, ebx
	mov [height], eax
_setup:
	fild word [height]
	fild word [width]
	fdivp
	fst dword [ratio]
	fst dword [y]
	mov eax, __float32__(-2.0)
	mov [temp], eax
	fld dword [temp]
	fmulp
	fild word [height]
	fdivp
	fstp dword [y_step]
	fld dword [ratio]
	mov ecx, __float32__(-1.0)
	mov [temp], ecx
	fld dword [temp]
	fmulp
	fstp dword [ratio] ; make ratio negative
_for_y:
	fld dword [y]
	fld dword [ratio]
	fcompp
	fnstsw ax
	sahf
	jp _y_end ; NaN
	ja _y_end ; y < -ratio

_set_x_step:
	mov ecx, __float32__(-1.0)
	mov [temp], ecx
	fld dword [temp]
	fst dword [x]
	mov ecx, __float32__(-2.0)
	mov [temp], ecx
	fld dword [temp]
	fmulp
	fild word [width]
	fdivp
	fstp dword [x_step]
_for_x:
	; loop checker
	; mov eax, 0x4
	; mov ebx, 0x1
	; mov ecx, achar
	; mov edx, 0x1
	; syscall
	fld dword [x]
	fld1
	fcompp ; 1 vs x
	fnstsw ax
	sahf
	jp _x_end ; NaN
	jb _x_end

	mov ecx, __float32__(0.0)
	mov [colour], ecx ; reset colour

	mov ecx, [x]
	mov [pixel], ecx
	mov ecx, [y]
	mov [pixel + 0x4], ecx ; pixel.z = 0.0f by default

	mov ecx, pixel
	mov edx, camera
	call _vec_sub
	call _normalise
	mov edx, [ecx]
	mov [dir], edx
	mov edx, [ecx + 0x4]
	mov [dir + 0x4], edx
	mov edx, [ecx + 0x8]
	mov [dir + 0x8], edx
	
; stack: (restored on output)
;(+0x00) *ret_location
; +0x04 *objs
; +0x08 num_of_objs
; +0x0B *ray_origin
; +0x10 *ray_direction
; eax out: is_none
; ecx out: float *min_distance (&min_disance)
; edx out: Sphere *nearest_obj
; flags out: eq=1 when none
; call _nearest_intersected_obj
	push dir
	push camera
	push dword [num_of_spheres]
	push spheres
	call _nearest_intersected_obj
_after_intersect:
	je _x_continue ; if there is no objects
	mov ecx, __float32__(1.0)
	mov [colour], ecx

_x_continue:
	fld dword [x]
	fld dword [x_step]
	faddp
	fstp dword [x] ; add x_step

	fld dword [colour]
	fld1
	fcompp
	fnstsw ax
	sahf
	jp _x_nan
	ja _x_less_than_1
	fld1
	fstp dword [colour]
	jmp _x_print
_x_less_than_1:
	fld dword [colour]
	fldz
	fcompp
	fnstsw ax
	sahf
	jp _x_nan
	jb _x_print
	fldz
	fstp dword [colour]
_x_print:
;;;;;;;;;;;;
	jmp _for_x
	fild word [bright_num]
	fld dword [colour]
	fmulp
	frndint
	fistp word [idx]
	mov ecx, brightness
	mov edx, [idx]
	and edx, 0xFFFF
	add ecx, edx
	mov eax, 0x4
	mov ebx, 0x1
	mov edx, 0x1
	push ecx
	syscall
	pop ecx
	mov eax, 0x4
	mov ebx, 0x1
	mov edx, 0x1
	syscall

	jmp _for_x
_x_end:
_x_nan:
_y_continue:
	fld dword [y]
	fld dword [y_step]
	faddp
	fstp dword [y]

	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, newln
	mov edx, 0x1
	syscall
	jmp _for_y
_y_end:
; stack:
;(+0x00) *ret_location
; +0x04 *center
; +0x08 *radius
; +0x0B *ray_origin
; +0x10 *ray_direction
	; push v1
	; push v2
	; push rad
	; push v1
	; call _sphere_intersection
	mov eax, 1		; Exit
	mov ebx, 0		; With no error
	syscall

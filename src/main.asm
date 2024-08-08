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
	%1_position:	dd %2, %3, %4
	%1_radius:		dd %5
	%1_ambient:		dd %6
	%1_diffuse:		dd %7
	%1_specular:	dd %8
	%1_shininess:	dd %9
%endmacro
%define sphere_size 0x20 ; spheres are 32 bytes
%define new_vec3 dd 0.0, 0.0, 0.0

section .data
	stringln helloWorld, "Hello, world!"
	string brightness, " .:-=+*#%@"
	num_of_spheres: db 0x2,
				   ; x    y    z   rad   amb  dif  spc  shi
	sphere spheres,-0.2, 0.0,-1.0, 0.7,  0.1, 0.7, 1.0, 100.0
				   ; x    y    z   rad   amb  dif  spc  shi
	sphere sphere1, 0.0, 9.e3,0.0,8999.3,0.1, 0.6, 1.0, 100.0
				   ; x    y    z   rad   amb  dif  spc  shi
	sphere light,   5.0, 5.0, 5.0, 0.0,  1.0,1.0, 1.0, 0.0
	camera: new_vec3
	width: db 75,
	height: db 70,
	ratio: dd 0.0,
	x: dd 0.0,
	x_step: dd 0.0,
	y: dd 0.0,
	y_step: dd 0.0,
	colour: dd 0.0,
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
	extern _parse_num, _print_num, _put_char			; std
	extern _dot, _norm, _normalise, _vec_add, _vec_sub	; vectors
	extern _sphere_intersection							; spheres

_start:
	pop ecx ; ETX char
	pop ecx ; path
	pop ecx ; width or null
	cmp ecx, 0x0
	je _no_args
	mov edx, 4
	call _parse_num

	xor edx, edx
	mov ebx, 0x2
	div ebx
	mov [width], eax

	pop ecx ; height or null
	cmp ecx, 0x0
	je _no_args
	mov edx, 4
	call _parse_num

	mov ebx, 0xA
	sub eax, ebx
	mov [height], eax
_no_args:
	mov eax, [width]
	mov ebx, 0xA
	call _print_num
	mov eax, 0xA
	call _put_char
	mov eax, [height]
	mov ebx, 0xA
	call _print_num
	mov eax, 0xA
	call _put_char

	mov eax, 4				; Put the system call for write
	mov ebx, 1				; To the std output
	mov ecx, helloWorld		; Give the *char
	mov edx, helloWorld_len	; Give the length of the buffer
	syscall					; Tell the kernel to do it

_end:
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

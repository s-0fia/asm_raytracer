# Simple sphere raytracer in Assembly
This is made with x86 NASM, and works on intel.
The target must have FPU operations for this to function.

---
# Usage
## Building
Simple do `make` while in the project root to make this project, and run it by doing either `./target/main` or `./target/main WIDTH HEIGHT` to give the raytracer a specific width and height to render to.

*Note: The width undergoes `(w-2)/2` and the height undergoes `h-10` when ran.*

Do `make run` to run this automatically with your terminal width and height passed into the program.

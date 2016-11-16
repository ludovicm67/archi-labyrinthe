#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
# Copyright (C) 2016 Maxime Schmitt <max.schmitt@math.unistra.fr>
#
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long
# as the name is changed.
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

.data
seed: .word 0xfaceb00c, 0xdeadbeef
max_float_alea: .float 2147483647

.text
.globl __start

# Point d'entrée du programme
__start:
li $a0, 0
li $a1, 101
jal nombre_alea_entre_deux_bornes
move $a0, $v0
li $v0, 1
syscall
j exit

# Retourne un nombre aléatoire inclus dans l'intervalle [$a0,$a1[
# Paramètres : a passé dans $a0 et b passé dans $a1
# Pré-conditions : 0 <= $a0 < $a1
# Résultat : le nombre aléatoire dans le registre $v0
nombre_alea_entre_deux_bornes:
# Prologue
subu $sp, $sp, 12
sw $ra, ($sp)
swc1 $f0, 4($sp)
swc1 $f1, 8($sp)
# Corps
jal random_generator
andi $v0, $v0, 0x7fffffff
mtc1 $v0, $f0
cvt.s.w $f0, $f0
lwc1 $f1, max_float_alea
div.s $f0, $f0, $f1
sub $a1, $a1, $a0
mtc1 $a1, $f1
cvt.s.w $f1, $f1
mul.s $f0, $f0, $f1
mtc1 $a0, $f1
cvt.s.w $f1, $f1
add.s $f0, $f0, $f1
cvt.w.s $f0, $f0
mfc1 $v0, $f0
# Épilogue
lw $ra, ($sp)
lwc1 $f0, 4($sp)
lwc1 $f1, 8($sp)
addu $sp, $sp, 12
jr $ra

# Function random_generator
# Retourne un nombre aléatoire entre 0 et 2^32-1
# Paramètres :
# Résultat : Le nombre aléatoire dans $v0
random_generator:
# Prologue
# Corps
lw $t0, seed
andi $t1, $t0, 65535
mulu $t1, $t1, 36969
srl $t2, $t0, 16
addu $t0, $t1, $t2
lw $t1, seed+4
andi $t2, $t1, 65535
mulu $t2, $t2, 18000
srl $t3, $t1, 16
addu $t1 $t2, $t3
sw $t0, seed
sw $t1, seed+4
sll $v0, $t0, 16
addu $v0, $v0, $t1
# Épilogue
jr $ra

exit:
li $v0, 10
syscall

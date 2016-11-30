.data


chaine1:
    .asciiz "wesh"
    
chaine2:
    .asciiz " gros"
.text
.globl __start

# Point d'entrée du programme
__start:
    la $a0 chaine1
    move $t0 $a0
    la $a1 chaine2
    move $t2 $a1
    Parcours1:
    lb $a0 0($t0) #on accede au premier caractere
    beqz $a0 Parcours2 #Si la première chaine est parcourue on va à la deuxieme
    addi $t0 $t0 1 #Sinon on continue de parcourir la chaine
    j Parcours1
    
    Parcours2:
    lb $a0 0($t2) # on met le caractere dans la chaine1
    beqz $a1 Fin #Si la première chaine est parcourue on a fini
    sb $a1 0($t0)
    addi $t2 $t2 1 #Sinon on continue de parcourir la chaine
    addi $t0 $t0 1
    j Fin
    
    j Parcours2
    
    Fin:
    la $a0 chaine1
    li $v0 4
    syscall
    
    j Exit
    
    # Fin du programme
Exit:
    li $v0 10
    syscall
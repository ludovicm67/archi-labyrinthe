.data


Demande: .asciiz "Veuillez entrer un entier strictement supérieur à 0: "
Erreur: .asciiz "Le nombre ne convient pas, réessayez: "

.text
.globl __start

__start:

j Affichage #Affichage de la demande à l'utilisateur

Affichage: 
la $a0 Demande #Chargement de la chaîne de caractère Demande dans $a0
li $v0 4 #Affichage de la chaîne Demande
syscall #Appel système

li $v0 5 #On lit l'entier que l'utilisateur a entré
syscall

j Generation 

Generation:
move $a0 $v0 #On déplace la valeur que l'utilisateur a entré dans $v0
li $v1, 0 #On attribye la valeur 0 à $v1
ble $v0, $v1, Else #On test si $v0<=0 si c'est vrai on jump au Else
li $v0 1 #sinon on affiche $v0
syscall
j Exit #Le programme est finit

Else: 
j Affichage #Si $v0 est négatif, on recommence 

Exit:
li $v0 10 #appel système 10: fin du programme
syscall
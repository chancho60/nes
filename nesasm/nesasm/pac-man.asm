;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   PACMAN!!!
;	Création: Étienne Boisjoli
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;; Entète de la rom ;;;;;;;;;;;
	.inesprg 1 ; 1 banque de 16KB (2 banque de 8KB) pour le programme
	.ineschr 1 ; 1 banque de 8KB pour les image (2 tables de motifs)
	.inesmap 0 ; mapper 0 = NROM, Banque par défaut
	.inesmir 1 ; Mirroir vertical de l'image de fond

;;;;;;; Le code commence ici ;;;;;;;;
	.code

	.bank 0   ; Banque 0 (8KB de $0000 à $DFFF
	.org $8000  ; goto location $8000.


Start:
	SEI         ; Arreter les interruption, Met le bit I du registre P (etat du processeur) a 1
	CLD         ; Arrete le mode decimal. Met le bit D du registre P à 0
	LDX #$40
	STX $4017  ;  Met $40 dans le registre de controle de l'APU pour arreter les interruptions de l'APU
	LDX #$FF
	TXS         ; Initialise la pile. Place X ($FF$ comme octet moins significatif de l'adresse de la pile). La pile est toujours entre $0100 et $01FF.
	INX         ; Lorsqu'on incremente X qui contient $FF, C tombe à 0
	STX $2000  ;  Arrete les interruption NMI (Bit 7 du registre Contrôle PPU)
	STX $2001  ;  N'affiche rien (Voir bits 3 à 7 du registre Masque PPU)
	STX $4010  ;  Arrete les interruption logiciel

vblankwait1:
	BIT $2002		; Bit place les Code de condition N, V, Z.
	BPL vblankwait1	; Si le bit 7 est allumé, on a un vblank (BPL = N flag clear, le bit de negatif = bit 7)

clrmem:
	LDA #$00
	;STA $0000,  x		; Place tous les octets à 0 (", x" correspond a l'adressage indexe avec le registre x)
	STA $0100,  x
	STA $0300,  x
	STA $0400,  x
	STA $0500,  x
	STA $0600,  x
	STA $0700, x
	LDA #$FE
	STA $0200, x		; Placer tous les sprite en dehors de l'écran
	INX
	BNE clrmem		; Branche si non zero (lorsque x a fait le tour des valeurs de 0 à FF)

vblankwait2:			; Attent le prochain vblank (voir vblankwait1)
	BIT $2002
	BPL vblankwait2


;;;;  Initialise le PPU  ;;;;

LoadPalettes:
 	LDA $2002    		; Lire le registre d'etat du PPU ou annuler le latch de $2006 (s'il y a lieu)
	LDA #$3F	
	STA $2006    		; Place les 8 bits les plus significatifs de l'adresse $3F00 dans $2006
	LDA #$00
	STA $2006    		; Place les 8 bits les moins significatifs de l'adresse $3F00 dans $2006
	LDX #$00
LoadPalettesLoop:
	LDA Palette, x		; Charge les donnees de la palette (", x" correspond a l'adressage indexe avec le registre x)
	STA $2007		; Place les informations du PPU (l'adresse d'écriture de $2007 incrémente automatiquement de 1 octet après chaque ecriture)
	INX			; Prochain index a aller chercher dans la palette en memoire rom (etiquette palette+x)
	CPX #$20            
	BNE LoadPalettesLoop 	; La palette est completement copiees si x est à $20=32=16x2

; Initialisation des sprites
	LDX #$00
LoadSpritesData:
	LDA SpriteData, x
	STA $0200, x
	INX
	CPX #$40
	BNE LoadSpritesData
	

;;;;  Fin de l'initialisation du PPU  ;;;;

;;;;  Commencer l'affichage du PPU  ;;;;


vblankwait3:		; Attent le prochain vblank
	BIT $2002
	BPL vblankwait3

activePPU:
	LDA #%10010100		; Active les interruption NMI, table de motif: sprite = 0 et image de fond = 1
	STA $2000
	LDA #%00010110		; Active l'image de fond et les sprites
	STA $2001


Forever:
	LDX #$00
	LDY #$00
	LDA #$01	; Écrire $01 et $00 dans $4016 place l'état du controlleur 1 dans $4016 et du controlleur 2 dans $4017
	STA $4016
	LDA #$00
	STA $4016
ReadButtonLoop:			; Valide chaque bouton
	LDA $4016, y		; Lit l'état du controlleur
	AND #%00000001		; Le bouton est appuyé si le AND ne retourne pas 0.
	BEQ NotReadButton
	ORA $0202, x		; Bouton pressé
	STA $0202, x
	JMP FinReadButtonCTRL
NotReadButton:			; Bouton non pressé
	LDA #%11111100
	AND $0202, x
	STA $0202, x
FinReadButtonCTRL:
	INX
	INX
	INX
	INX
	CPX #32			; Controller 1 terminé
	BNE FinReadButton1
	INY
	JMP ReadButtonLoop
FinReadButton1
	CPX #64			; Controller 2 terminé
	BNE ReadButtonLoop



	JMP Forever     ;Boucle sans fin, le processus se fera lors d'interruption


NMI:

	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

	LDA #%10010100		; Active les interruption NMI, table de motif: sprite = 0 et image de fond = 1
	STA $2000
	LDA #%00011110		; Active l'image de fond et les sprites
	STA $2001

	RTI             ; retourne de l'interruption


;;;;; La prochaine section est une partie du ROM de la cartouche il est possible de mettre du code ici. Nous allons l'utiliser pour mettre des constantes ;;;;;;

	.bank 1		; Banque 1 (8KB de $E000 à $FFFF)
	.org $E000	; Donnees en lecture seulement (similaire au rodata)

Palette:
	.db $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; Palette de l'image de fond
	.db $09, $10, $10, $10, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F	; Palette des sprites


SpriteData:
	.db $40, 0, %00000000, $10	; pacmanHG
	.db $40, 1, %00000000, $18	; pacmanHD
	.db $48, 2, %00000000, $10	; pacmanBG
	.db $48, 3, %00000000, $18	; pacmanBD
	.db $40, 4, %00000000, $8C	; bleuHG
	.db $40, 5, %00000000, $AB	; bleuHD
	.db $40, 6, %00000000, $CA	; bleuBG
	.db $40, 7, %00000000, $E9	; bleuBD
	.db $40, 0, %00000000, $10	; rougeHG
	.db $40, 1, %00000000, $18	; rougeHD
	.db $48, 2, %00000000, $10	; rougeBG
	.db $48, 3, %00000000, $18	; rougeBD
	.db $40, 4, %00000000, $8C	; roseHG
	.db $40, 5, %00000000, $AB	; roseHD
	.db $40, 6, %00000000, $CA	; roseBG
	.db $40, 7, %00000000, $E9	; roseBD

	.org $FFFA	; vecteur d'interruption commence à $FFFA

	.dw NMI		; Interruption NMI (vblank). Adresse $FFFA
	.dw Start	; Interruption Reset (demarrage). Adresse $FFFC
	.dw 0		; Interruption logiciel (instruction BRK). Adresse $FFFE




;;;;; La prochaine section est une partie du ROM qui correspond aux adresse $0000 à $1FFF de la vram du PPU ;;;;;;

	.bank 2     ; change to bank 2
	.org $0000	; Motif de Sprite
SpritePacmanHG:	; Tuile 0
	.db %00000111
	.db %00001111 
	.db %00011111
	.db %00111111
	.db %00111111
	.db %01111111
	.db %11111111
	.db %11111111

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
SpritePacmanHD:	; Tuile 1
	.db %11100000
	.db %11110000 
	.db %11111000
	.db %11111100
	.db %11111100
	.db %11111000
	.db %11100000
	.db %10000000

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
SpritePacmanBG:	; Tuile 3
	.db %11111111 
	.db %11111111
	.db %01111111 
	.db %00111111
	.db %00111111
	.db %00011111
	.db %00001111
	.db %00000111

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
SpritePacmanBD:	; Tuile 3
	.db %10000000 
	.db %11100000
	.db %11111000 
	.db %11111100
	.db %11111100
	.db %11111000
	.db %11110000
	.db %11100000

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteBleuHG:	; Tuile 4
	.db %00000111
	.db %00001111 
	.db %00011111
	.db %00111111
	.db %00111111
	.db %01111111
	.db %11111111
	.db %11111111

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
SpriteBleuHD:	; Tuile 5
	.db %11100000 
	.db %11110000
	.db %11111000 
	.db %11111100
	.db %11111100
	.db %11111110
	.db %11111111
	.db %11111111

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteBleuBG:	; Tuile 6
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteBleuBD:	; Tuile 7
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000	

SpriteRougeHG:	; Tuile 8
	.db %00000111
	.db %00001111 
	.db %00011111
	.db %00111111
	.db %00111111
	.db %01111111
	.db %11111111
	.db %11111111

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
SpriteRougeHD:	; Tuile 9
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteRougeBG:	; Tuile A
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteRougeBD:	; Tuile B
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteRoseHG:	; Tuile C
	.db %00000111
	.db %00001111 
	.db %00011111
	.db %00111111
	.db %00111111
	.db %01111111
	.db %11111111
	.db %11111111

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
SpriteRoseHD:	; Tuile D
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteRoseBG:	; Tuile E
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

SpriteRoseBD:	; Tuile F
	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000 

	.db %00000000 
	.db %00000000
	.db %00000000 
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000



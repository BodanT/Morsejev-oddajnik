# Kraten opis koda

## Najpomebnejše dele koda

Glavni program predstavlja neskončno zanko, ki prejme niz znakov na začetku. Nato se ta niz obdela in pošlje preko FRI-SMS, ki na koncu prikaže sporočilo na lučki. Ta postopek se nenehno ponavlja, saj je program v neskončni zanki.
SNDS_DEBUG je podprogram, ki sprejme niz znakov, shranjen v določeni spremenljivki, in ga pošlje na terminal. Na začetku je prikazan informativni niz, ki vsebuje navodila za uporabnika.

Testni:  .asciz "\nType string(max 100) to be sent to Morse Code\n"

Nato uporabnik lahko vpiše poljuben niz znakov preko terminala, ki ga obdela podprogram RCVS_DEBUG in ta niz shrani v spremenljivko Received. Za končanje vnosa, uporabnik pritisne tipko ENTER. Končno sporočilo je izpisano na terminalu in preko podprograma XWORD (ki vsebuje več podprogramov) se ta niz pretvori v Morsejevo kodo.

```
INFINITE:
adr r0,Testni
bl SNDS_DEBUG

adr r0,Received
mov r1,#3
bl RCVS_DEBUG
adr r0, Received
bl SNDS_DEBUG
adr r0, Received
bl XWORD
b INFINITE
```

Transformacija niza v Morsejevo kodo je izvedena v podprogramu XWORD. Ta podprogram uporablja podprogram GETMCODE, ki prevaja ASCII znake v Morsejevo kodo (- in .). Za vsak znak v nizu preveri, ali je enak ničli, kar označuje konec niza. Če ni enak ničli, odšteje 65 od vrednosti znaka, da ugotovi njegovo zaporedno mesto v abecedi. Nato uporabi pomožno tabelo, ki vsebuje Morsejeve kode za vsako črko. 
Z znano pozicijo črke v abecedi pomnoži s 6 in prebere ustrezno Morsejevo kodo iz pomožne tabele. Te Morsejeve kode, ki vsebujejo samo pike in črte, so shranjene na začasnem naslovu, da jih lahko uporabimo v nadaljevanju.

```
XWORD:
  stmfd r13!, {lr}
  bl GETMCODE
  mov r1, r0
  bl XMCODE
  bl KASNI_SEK 
  ldmfd r13!, {pc}

GETMCODE:
  stmfd r13!, {r2,r3,r4,r5, r6,r7, lr}
  adr r7, CUVAJ   
  adr r2, ZNAKI   
  mov r6, #6
  START1:
    ldrb r3,[r0]  
    cmp r3,#0
    beq END1
    sub r3,r3,#65 
    mul r3,r6  
    
  CITAJ_KOD:
    ldrb r4,[r2, r3] 
    cmp r4,#0
    beq SLEDNA_BUKVA
    strb r4,[r7]
    add r7,r7,#1     
    add r3,r3,#1    
    b CITAJ_KOD

  SLEDNA_BUKVA:  
    add r0,r0,#1 
    b START1 
    mov r4, #0
    add r7,r7,#1
    strb r4,[r7]
    adr r0, CUVAJ 
  ldmfd r13!, {r2,r3,r4,r5,r6,r7, pc}
```

Za prenos Morsejeve kode na lučko uporabljamo podprogram XMCODE. Ta podprogram je sestavljen iz enostavne neskončne zanke, ki iterira skozi vse Morsejeve kode. Preverja, ali je trenutni znak enak ničli. Če ni ničla, se kliče podprogram XMCHAR.
V podprogramu XMCHAR preverjamo, ali gre za piko ali črto. Če je pika, se kliče podprogram TOCKA, ki vklopi lučko, počaka 150 ms, nato jo izklopi in spet čaka 300 ms. Če gre za črto, se kliče podprogram CRTA, ki izvaja podobne korake, vendar čaka 300 ms.
Na ta način se Morsejeva koda pretvori v svetlobne impulze na lučki, ki ustvarjajo vizualni prikaz na podlagi pike in črte.

```
XMCODE:
  stmfd r13!, {lr}
  
  START:  
    ldrb r0,[r1]     
    cmp  r0,#0       
    beq END
    bl XMCHAR       
    add r1,r1,#1     
    b START
  END:
    bl KASNI_NIZA    
       
  ldmfd r13!, {pc}

XMCHAR:
  stmfd r13!, {lr}
  cmp r0, #'.' 
  beq TOCKA
  cmp r0, #'-'
  beq CRTA 
  
  ldmfd r13!, {pc}

```

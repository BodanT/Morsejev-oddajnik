# Kraten opis koda

## Najpomebnejše dele koda

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

Glavni program predstavlja neskončno zanko, ki prejme niz znakov na začetku. Nato se ta niz obdela in pošlje preko FRI-SMS, ki na koncu prikaže sporočilo na lučki. Ta postopek se nenehno ponavlja, saj je program v neskončni zanki.

SNDS_DEBUG je podprogram, ki sprejme niz znakov, shranjen v določeni spremenljivki, in ga pošlje na terminal. Na začetku je prikazan informativni niz, ki vsebuje navodila za uporabnika.

Testni:  .asciz "\nType string(max 100) to be sent to Morse Code\n"

Nato uporabnik lahko vpiše poljuben niz znakov preko terminala, ki ga obdela podprogram RCVS_DEBUG in ta niz shrani v spremenljivko Received. Za končanje vnosa, uporabnik pritisne tipko ENTER. Končno sporočilo je izpisano na terminalu in preko podprograma XWORD (ki vsebuje več podprogramov) se ta niz pretvori v Morsejevo kodo.

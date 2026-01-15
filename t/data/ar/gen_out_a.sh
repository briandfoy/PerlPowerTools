#!/bin/sh
rm -rf out*.a

ar qc out01.a a b c

ar rc out02.a a b c

ar qc out03.a a b c
ar r out03.a another/a

ar qc out04.a a b c
ar d out04.a a

ar qc out05.a a b c another/a


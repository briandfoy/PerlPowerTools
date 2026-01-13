#!/bin/sh

rm -rf out*

ar q out01.a a b c

ar rc out02.a a b c

ar q out03.a a b c
ar r out03.a ./another_a/a

ar q out04.a a b c
ar d out04.a a

ar q out05.a a b c ./another_a/a

program COMPLETO

symbol led = portd.2
symbol led_pid = portc.4
const kp = 0
const kd = 0
const ki = 10
const tempo = 10
const limite_pid = 2800
const limite_integr = 2900
dim s_read as word
dim s1 as integer
dim j as byte
dim orientation as integer[40]
dim somma_or as float
dim proportional as integer
dim integrative as integer
dim derivative as integer
dim pid as integer
dim duty_perc as float
dim duty as float
dim duty_byte as byte

main:

'PER SICUREZZA AZZERO TUTTI I BIT DEI REGISTRI'''''''''''''''''''''''''''''
''initialize all registers to zero
INTCON=0
OPTION_REG=0
ADCON0=0
ADCON1=0

TRISA=%11111
TRISB=0
TRISC=0
TRISD=0
TRISE=0

s1=0
pid=0

'SETTA I PARAMETRI LETTURA PORTE ANALOGICHE''''''''''''''''''''''''''''''''''
''set reading gates 
ADCON0=%10000101
ADCON1=%10110000
'risultato giustificato verso destra
'AN1 bit che si deve comportare come ingresso analogico
'AN2 tensione di riferimento negativa
'AN3 tensione di riferimento positiva
''result justified on the right
''AN1 bit that behaves as analog input
''AN2 zero voltage
''AN3 positive voltage


'SETTA I PARAMETRI RELATIVI A PWM''''''''''''''''''''''''''''''''''''''''
''initialize PWM params
Pwm1_Init(20000)        ' Inizializza il modulo PWM1, frequenza=20kHz
Pwm2_Init(20000)        ' Inizializza il modulo PWM2, frequenza=20kHz

portb.0=0
portb.1=1
portb.2=0
portb.3=1

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

delay_ms(1000)
led=1
delay_ms(1000)
led=0
delay_ms(1000)
led=1
delay_ms(1000)
led=0

pippo:
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
s_read=Adc_Read(1)
s1=s_read  'conversione implicita   ''implicit conversion


if s1<130 then
s1=130
led=1
end if

if s1>190 then
s1=190
led=1
end if

if (s1>130) and (s1<190) then
led=0
end if

'dividiamo i 2 campi di funzionamento e ne ricaviamo da entrambi orientation<=500
''split job between going back and going forward 

''''''''''''''''''2222222222222222222222222'''''''''''''''''''''''''''''''''

if s1<146 then

s1=s1-146
orientation[0]=s1*85/2           ' 0<=orientation<=-680

somma_or=0
for j=40 to 1
orientation[j]=orientation[j-1]
next j
for j=0 to 40
somma_or=somma_or + orientation[j]
next j

proportional=(orientation[0])*kp
integrative=somma_or/ki
derivative=(orientation[0]-orientation[1])*kd

'limitiamo l'integrale
''limit the integer
if (integrative>-limite_integr) and (integrative<limite_integr) then
   portd.2=0
end if
if integrative>=limite_integr then
   portd.2=1
   integrative=limite_integr
end if
if integrative<=-limite_integr then
   portd.2=1
   integrative=-limite_integr
end if

if derivative>0 then
derivative=0
end if

pid=proportional+integrative+derivative

'eliminazione di valori anomali a fondo scala e valori troppo prossimi allo zero
''clean up too little and too large values
if pid>=limite_pid then
   pid=limite_pid
   led_pid=1
end if
if pid<=-limite_pid then
   pid=-limite_pid
   led_pid=1
end if
'if (pid>=-2) and (pid<=2) then
'   pid=0
'   portc.4=0
'end if
if (pid<limite_pid) and (pid>-limite_pid) then
   led_pid=0
end if

'PORTB0  e PORTB1 comandano i transistor del ponte h che invertono
'l'alimentazione fornita al motore1, mentre PORTB2 e PORTB3 comandano la
'direzione del motore2, permettendo loro di cambiare il proprio senso di marcia
''PORTB0 and PORTB1 control the H-Bridge for engine1
''PORTB2 and PORTB3 control the H-Bridge for engine2
''this allow us to change their direction
portb.0=1
portb.1=0
portb.2=1
portb.3=0

'definiamo il valore percentuale del duty cycle che dovremo fornire ai motori sarà quindi: 0<duty%<100
''determine duty-cycle for the engines: 0<duty%<100
duty_perc=(pid*100)/limite_pid

'la funzione PWM di mikrobasic accetta valori compresi tra 0 e 255,
'dove 0 è 0%, 127 è 50%, and 255 è 100% del duty cycle
'dovremo quindi convertire il valore duty_perc appena calcolato
''mikrobasic's PWM accepts values between 0 and 255,
''convert the duty-cycle just calculated
duty=-(duty_perc * 255 / 100)

'ora regoliamo la tensione di alimentazione del motore
'PWM1 dirige il segnale alla porta CCP1,cioè RC2
'PWM2 dirige il segnale alla porta CCP2,cioè RC1
'la funzione pwm_change_duty accetta soltanto variabili del tipo byte
'la conversione implicita prevede che soltanto i bit più significativi vengano
'persi; essendo che la variabile duty(integer) contiene un valore al massimo
'pari a 100, posso tranquillamente utilizzare la conversione implicita
''adjust voltage for the engine
''PWM1 sends the signal to CCP1, that is RC2
''PWM2 sends the signal to CCP2, that is RC1
''Pwm_Change_Duty accepts only byte values
duty_byte=duty
Pwm1_Change_Duty(duty_byte)
Pwm2_Change_Duty(duty_byte)
Pwm1_Start
Pwm2_Start

end if

''''''''''''''''''''''11111111111111111111111111''''''''''''''''''''''''''''

if s1>146 then

s1=s1-146
orientation[0]=s1*125/11             ' 0<=orientation<=500

somma_or=0
for j=40 to 1
orientation[j]=orientation[j-1]
next j
for j=0 to 40
somma_or=somma_or + orientation[j]
next j

proportional=(orientation[0])*kp
integrative=somma_or/ki
derivative=(orientation[0]-orientation[1])*kd

'limitiamo l'integrale
''limit the integer
if (integrative>-limite_integr) and (integrative<limite_integr) then
   portd.2=0
end if
if integrative>=limite_integr then
   portd.2=1
   integrative=limite_integr
end if
if integrative<=-limite_integr then
   portd.2=1
   integrative=-limite_integr
end if

if derivative<0 then
derivative=0
end if

pid=proportional+integrative+derivative

'eliminazione di valori anomali a fondo scala e valori troppo prossimi allo zero
''clean up too little and too large values
if pid>=limite_pid then
   pid=limite_pid
   led_pid=1
end if
if pid<=-limite_pid then
   pid=-limite_pid
   led_pid=1
end if
'if (pid>=-2) and (pid<=2) then
'   pid=0
'   portc.4=0
'end if
if (pid<limite_pid) and (pid>-limite_pid) then
   led_pid=0
end if

'PORTB0  e PORTB1 comandano i transistor del ponte h che invertono
'l'alimentazione fornita al motore1, mentre PORTB2 e PORTB3 comandano la
'direzione del motore2, permettendo loro di cambiare il proprio senso di marcia
''PORTB0 and PORTB1 control the H-Bridge for engine1
''PORTB2 and PORTB3 control the H-Bridge for engine2
''this allow us to change their direction
portb.0=0
portb.1=1
portb.2=0
portb.3=1

'definiamo il valore percentuale del duty cycle che dovremo fornire ai motori
'sarà quindi: 0<duty%<100
''determine duty-cycle for the engines: 0<duty%<100
duty_perc=(pid*100)/limite_pid

'la funzione PWM di mikrobasic accetta valori compresi tra 0 e 255,
'dove 0 è 0%, 127 è 50%, and 255 è 100% del duty cycle
'dovremo quindi convertire il valore duty_perc appena calcolato
''mikrobasic's PWM accepts values between 0 and 255,
''convert the duty-cycle just calculated
duty=duty_perc * 255 / 100

'ora regoliamo la tensione di alimentazione del motore
'PWM1 dirige il segnale alla porta CCP1,cioè RC2
'PWM2 dirige il segnale alla porta CCP2,cioè RC1
'la funzione pwm_change_duty accetta soltanto variabili del tipo byte
'la conversione implicita prevede che soltanto i bit più significativi vengano
'persi; essendo che la variabile duty(integer) contiene un valore al massimo
'pari a 100, posso tranquillamente utilizzare la conversione implicita
''adjust voltage for the engine
''PWM1 sends the signal to CCP1, that is RC2
''PWM2 sends the signal to CCP2, that is RC1
''Pwm_Change_Duty accepts only byte values
duty_byte=duty
Pwm1_Change_Duty(duty_byte)
Pwm2_Change_Duty(duty_byte)
Pwm1_Start
Pwm2_Start

end if

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
goto pippo
end.
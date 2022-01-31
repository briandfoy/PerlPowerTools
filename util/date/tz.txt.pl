#!/Users/brian/bin/perl
use v5.10;
use strict;
use DateTime::TimeZone;
use DateTime;


while( <DATA> ) {
chomp;
my( $windows, $olson ) = split /,/;
unless( $olson ) {
	say "$_,";
	next;
	}

my $tz = DateTime::TimeZone->new( name => $olson );

my $jan  = DateTime->new( year => 2021, month => 1, day => 1, time_zone => $olson );
my $july = DateTime->new( year => 2021, month => 7, day => 1, time_zone => $olson );

if( ! $jan->is_dst and ! $july->is_dst and $windows =~ /Daylight/ ) { say "!!! Olsen: no dst!" }

my( $dst_dt, $standard_dt ) = $jan->is_dst ? ( $jan, $july ) : ( $july, $jan );

my $dt = $windows =~ /Daylight/ ? $dst_dt : $standard_dt;

my $offset - DateTime::TimeZone->offset_as_string( $dt );

my $zone = $tz->short_name_for_datetime( $dt );
$zone .= '00' if $zone =~ /\A[+-]\d\d\z/;

say join ',', $_, $offset, $zone;
}


__END__
Afghanistan Standard Time,Asia/Kabul
Alaskan Daylight Time,America/Anchorage
Alaskan Standard Time,America/Anchorage
Aleutian Daylight Time,America/Adak
Aleutian Standard Time,America/Adak
Altai Standard Time,Asia/Barnaul
Arab Standard Time,Asia/Riyadh
Arabian Standard Time,Asia/Riyadh
Arabic Standard Time,Asia/Baghdad
Argentina Standard Time,America/Argentina/Cordoba
Astrakhan Standard Time,Europe/Astrakhan
Atlantic Daylight Time,America/Halifax
Atlantic Standard Time,America/Halifax
AUS Central Standard Time,Australia/Adelaide
Aus Central W. Standard Time,Australia/Eucla
AUS Eastern Standard Time,Australia/Sydney
Azerbaijan Standard Time,Asia/Baku
Azores Daylight Time,Atlantic/Azores
Azores Standard Time,Atlantic/Azores
Bahia Standard Time,America/Bahia
Bangladesh Standard Time,Asia/Dhaka
Belarus Standard Time,Europe/Minsk
Bougainville Standard Time,Pacific/Bougainville
Cabo Verde Standard Time,Atlantic/Cape_Verde
Canada Central Standard Time,America/Regina
Cape Verde Standard Time,Atlantic/Cape_Verde
Caucasus Standard Time,Asia/Tbilisi
Cen. Australia Standard Time,Australia/Adelaide
Central America Standard Time,America/Belize
Central Asia Standard Time,Asia/Almaty
Central Brazilian Standard Time,America/Cuiaba
Central Daylight Time (Mexico),America/Mexico_City
Central Daylight Time,America/Chicago
Central Europe Daylight Time,Europe/Paris
Central Europe Standard Time,Europe/Paris
Central European Daylight Time,Europe/Paris
Central European Standard Time,Europe/Paris
Central Pacific Standard Time,Pacific/Guadalcanal
Central Standard Time (Mexico),America/Mexico_City
Central Standard Time,America/Chicago
Chatham Islands Standard Time,Pacific/Chatham
China Standard Time,Asia/Shanghai
Cuba Daylight Time,America/Havana
Cuba Standard Time,America/Havana
Dateline Standard Time,
E. Africa Standard Time,Africa/Nairobi
E. Australia Standard Time,Australia/Sydney
E. Europe Daylight Time,Europe/Bucharest
E. Europe Standard Time,Europe/Bucharest
E. South America Standard Time,America/Argentina/Cordoba
Easter Island Standard Time,Pacific/Easter
Eastern Daylight Time,America/New_York
Eastern Standard Time,America/New_York
Egypt Standard Time,Africa/Cairo
Ekaterinburg Standard Time,Asia/Yekaterinburg
Fiji Standard Time,Pacific/Fiji
FLE Daylight Time,Europe/Helsinki
FLE Standard Time,Europe/Helsinki
Further-Eastern European Time,Europe/Minsk
Georgian Standard Time,Asia/Tbilisi
GMT Daylight Time,Greenwich
GMT Standard Time,Greenwich
Greenland Daylight Time,America/Nuuk
Greenland Standard Time,America/Nuuk
Greenwich Standard Time,Greenwich
GTB Daylight Time,Europe/Athens
GTB Standard Time,Europe/Athens
Haiti Daylight Time,America/Port-au-Prince
Haiti Standard Time,America/Port-au-Prince
Hawaiian Standard Time,Pacific/Honolulu
India Standard Time,Asia/Kolkata
Iran Daylight Time,Asia/Tehran
Iran Standard Time,Asia/Tehran
Israel Standard Time,Asia/Jerusalem
Jerusalem Daylight Time,Asia/Jerusalem
Jerusalem Standard Time,Asia/Jerusalem
Jordan Daylight Time,Asia/Amman
Jordan Standard Time,Asia/Amman
Kaliningrad Standard Time,Europe/Kaliningrad
Korea Standard Time,Asia/Seoul
Libya Standard Time,Africa/Tripoli
Line Islands Standard Time,Pacific/Kiritimati
Lord Howe Standard Time,Australia/Lord_Howe
Magadan Standard Time,Asia/Magadan
Magallanes Standard Time,America/Punta_Arenas
Malay Penisula Standard Time,Asia/Kuala_Lumpur
Marquesas Standard Time,Pacific/Marquesas
Mauritius Standard Time,Indian/Mauritius
Mexico Standard Time 2,
Mexico Standard Time,
Mid-Atlantic Standard Time,
Middle East Daylight Time,Asia/Beirut
Middle East Standard Time,Asia/Beirut
Montevideo Standard Time,America/Montevideo
Morocco Daylight Time,Africa/Casablanca
Morocco Standard Time,Africa/Casablanca
Mountain Daylight Time (Mexico),America/Chihuahua
Mountain Daylight Time,America/Denver
Mountain Standard Time (Mexico),America/Chihuahua
Mountain Standard Time,America/Denver
Myanmar Standard Time,Asia/Yangon
N. Central Asia Standard Time,Asia/Novosibirsk
Namibia Standard Time,Africa/Windhoek
Nepal Standard Time,Asia/Kathmandu
New Zealand Standard Time,Pacific/Auckland
Newfoundland and Labrador Standard Time,America/St_Johns
Newfoundland Daylight Time,America/St_Johns
Newfoundland Standard Time,America/St_Johns
Norfolk Standard Time,Pacific/Norfolk
North Asia East Standard Time,Asia/Irkutsk
North Asia Standard Time,Asia/Krasnoyarsk
North Korea Standard Time,Asia/Pyongyang
Novosibirsk Standard Time,Asia/Novosibirsk
Omsk Standard Time,Asia/Omsk
Pacific Daylight Time,America/Los_Angeles
Pacific SA Standard Time,America/Lima
Pacific Standard Time (Mexico),America/Tijuana
Pacific Standard Time,America/Los_Angeles
Pakistan Standard Time,Asia/Karachi
Paraguay Standard Time,America/Asuncion
Qyzylorda Standard Time,Asia/Qyzylorda
Romance Daylight Time,Europe/Paris
Romance Standard Time,Europe/Paris
Russia TZ 1 Standard Time,Europe/Kaliningrad
Russia TZ 2 Standard Time,Europe/Moscow
Russia TZ 3 Standard Time,Europe/Samara
Russia TZ 4 Standard Time,Asia/Yekaterinburg
Russia TZ 5 Standard Time,
Russia TZ 6 Standard Time,Asia/Krasnoyarsk
Russia TZ 7 Standard Time,Asia/Irkutsk
Russia TZ 8 Standard Time,Asia/Yakutsk
Russia TZ 9 Standard Time,Asia/Vladivostok
Russia TZ 10 Standard Time,Asia/Srednekolymsk
Russia TZ 11 Standard Time,Asia/Anadyr
Russian Standard Time,Europe/Moscow
SA Eastern Standard Time,America/Cayenne
SA Pacific Standard Time,America/Lima
SA Western Standard Time,America/La_Paz
Saint Pierre Daylight Time,America/Miquelon
Saint Pierre Standard Time,America/Miquelon
Sakhalin Standard Time,Asia/Sakhalin
Samoa Standard Time,Pacific/Apia
Sao Tome Standard Time,Africa/Sao_Tome
Saratov Standard Time,Europe/Saratov
SE Asia Standard Time,Asia/Jakarta
Singapore Standard Time,Asia/Singapore
South Africa Standard Time,Africa/Johannesburg
South Sudan Standard Time,Africa/Juba
Sri Lanka Standard Time,Asia/Colombo
Sudan Standard Time,Africa/Khartoum
Syria Daylight Time,Asia/Damascus
Syria Standard Time,Asia/Damascus
Taipei Standard Time,Asia/Taipei
Tasmania Standard Time,Australia/Hobart
Tocantins Standard Time,America/Araguaina
Tokyo Standard Time,Asia/Tokyo
Tomsk Standard Time,Asia/Tomsk
Tonga Standard Time,Pacific/Tongatapu
Transbaikal Standard Time,Asia/Chita
Turkey Standard Time,Europe/Istanbul
Turks and Caicos Daylight Time,America/Grand_Turk
Turks And Caicos Standard Time,America/Grand_Turk
U.S. Eastern Standard Time,America/New_York
Ulaanbaatar Standard Time,Asia/Ulaanbaatar
US Eastern Daylight Time,America/New_York
US Eastern Standard Time,America/New_York
US Mountain Standard Time,America/Denver
Venezuela Standard Time,America/Caracas
Vladivostok Standard Time,Asia/Vladivostok
Volgograd Standard Time,Europe/Volgograd
W. Australia Standard Time,Australia/Perth
W. Central Africa Standard Time,
W. Europe Daylight Time,Europe/London
W. Europe Standard Time,Europe/London
W. Mongolia Standard Time,Asia/Ulaanbaatar
West Asia Standard Time,Asia/Tashkent
West Bank Standard Time,Asia/Hebron
West Pacific Standard Time,Pacific/Port_Moresby
Yakutsk Standard Time,Asia/Yakutsk
Yukon Standard Time,America/Whitehorse

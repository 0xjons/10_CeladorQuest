//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

library TurnoLib {
    enum Turno {
        Manana,
        Noche
    }

    uint256 constant DESPLAZAMIENTO_ZONA_HORARIA = 2 hours; // Ajustar según tu zona horaria
    uint256 constant INICIO_MANANA = 8 hours; // 8 AM UTC+0
    uint256 constant FIN_MANANA = 20 hours; // 8 PM UTC+0
    uint256 constant INICIO_NOCHE = 20 hours; // 8 PM UTC+0

    function esTurnoCorrecto(Turno turno) internal view returns (bool) {
        uint256 horaDelDiaUTC = block.timestamp % 1 days;
        uint256 horaDelDiaLocal = (horaDelDiaUTC +
            DESPLAZAMIENTO_ZONA_HORARIA) % 1 days;

        if (turno == Turno.Manana) {
            return
                horaDelDiaLocal >= INICIO_MANANA &&
                horaDelDiaLocal < FIN_MANANA;
        } else if (turno == Turno.Noche) {
            // El turno de noche se extiende hasta la mañana siguiente
            return
                horaDelDiaLocal >= INICIO_NOCHE ||
                horaDelDiaLocal < INICIO_MANANA;
        }
        return false;
    }

    function determinarTurnoActual() internal view returns (uint256) {
        uint256 horaDelDiaUTC = block.timestamp % 1 days;
        uint256 horaDelDiaLocal = (horaDelDiaUTC +
            DESPLAZAMIENTO_ZONA_HORARIA) % 1 days;

        if (horaDelDiaLocal >= INICIO_MANANA && horaDelDiaLocal < FIN_MANANA) {
            return 0; // Manana
        } else {
            return 1; // Noche
        }
    }

    
}

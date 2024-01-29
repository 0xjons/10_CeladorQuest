# CeladorQuest & ImperivmERC20

## Descripción

Este repositorio contiene dos contratos inteligentes principales desarrollados en Solidity:

- **CeladorQuest**: Gestiona turnos y asignaciones para los puestos CAR y Q.
- **ImperivmERC20**: Un token ERC20 con funcionalidades de quemado y pausa.

## Características

- Gestión de turnos con asignaciones para roles en un juego.
- Token ERC20 con funcionalidades extendidas.
- Uso de `TurnoLib` para la lógica de turnos.
- Integración con el token ERC20 de OpenZeppelin.

## Instalación

1. Asegúrate de tener [Node.js](https://nodejs.org/) y [npm](https://www.npmjs.com/) instalados.
2. Instala [Truffle](https://www.trufflesuite.com/truffle) y [Ganache](https://www.trufflesuite.com/ganache) para desarrollo y pruebas locales.
3. Clona este repositorio.
4. Ejecuta `npm install` para instalar dependencias.
5. Usa Truffle con `truffle migrate` para desplegar los contratos.

## Uso

### CeladorQuest

- `masterCallerOne(TurnoLib.Turno turno)`: Asigna CAR y Q, distribuye tokens.
- `masterCallerTwo(TurnoLib.Turno turno)`: Asigna Secondary, distribuye tokens.
- `asignarCAR(TurnoLib.Turno turno)`: Asigna CAR en el turno actual.
- `asignarQ(TurnoLib.Turno turno)`: Asigna Q en el turno actual.
- `asignarSecondary(TurnoLib.Turno turno)`: Asigna Secondary en el turno actual.

### ImperivmERC20

- `pause()`: Pausa todas las transferencias de tokens.
- `unpause()`: Reanuda las transferencias de tokens.
- `mint(address to, uint256 amount)`: Crea tokens y los asigna a `to`.

## Contribuciones

Las contribuciones son bienvenidas. Envía un pull request o abre un issue para sugerencias.

## Licencia

- CeladorQuest: UNLICENSED
- ImperivmERC20: MIT
- TurnoLib: UNLICENSED

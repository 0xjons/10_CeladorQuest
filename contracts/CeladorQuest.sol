//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TurnoLib.sol";

/**
 * @title CeladorQuest
 * @dev Implementa la gestión de turnos y asignaciones para el puesto CAR y Q.
 */
contract CeladorQuest {
    using TurnoLib for TurnoLib.Turno;

    IERC20 public imperivmToken;

    address public owner;

    /**
     * @dev Estructura para almacenar información de turno, incluyendo asignaciones para CAR y Q.
     */
    struct InfoTurno {
        bool asignadoEnEsteTurnoCAR;
        bool asignadoEnEsteTurnoQ;
        bool asignadoEnEsteTurnoSecondary;
        uint256 diaDeAsignacion;
    }

    uint256 public indexActualCAR;
    uint256 public ultimoIndexCAR = 0;
    uint256 public ultimoIndexQ;
    uint256 public indexQ;
    uint256 public ultimoIndexSecondary;
    uint256 public indexSecondary;
    address[5] public rotacionCAR; // Se mantiene para la rotación del CAR

    uint256[5] public ordenAleatorioCAR;

    mapping(address => bool) public esWalletAutorizada;
    mapping(TurnoLib.Turno => InfoTurno) private asignacionesTurno;

    /**
     * @dev Constructor del contrato. Inicializa las wallets y establece al desplegador como propietario.
     */
    constructor(address _tokenAddress) {
        imperivmToken = IERC20(_tokenAddress);
        owner = msg.sender;

        // Cargar las wallets en el array y marcarlas como autorizadas
        rotacionCAR[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        rotacionCAR[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        rotacionCAR[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        rotacionCAR[3] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        rotacionCAR[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

        // Marcar todas las wallets como autorizadas
        for (uint256 i = 0; i < rotacionCAR.length; i++) {
            esWalletAutorizada[rotacionCAR[i]] = true;
        }
    }

    /**
     * @dev Modificador para restringir el acceso solo al propietario.
     */
    modifier soloOwner() {
        require(msg.sender == owner, "No autorizado");
        _;
    }
    /**
     * @dev Modificador para restringir el acceso solo a wallets autorizadas.
     */
    modifier soloAutorizado() {
        require(esWalletAutorizada[msg.sender], "Wallet no autorizada");
        _;
    }

    modifier hasImperivms() {
        require(
            imperivmToken.balanceOf(msg.sender) >= 1 * (10**18),
            "Saldo insuficiente de IMP"
        );
        require(
            imperivmToken.allowance(msg.sender, address(this)) >= 1 * (10**18),
            "Falta de aprobacion de IMP"
        );
        _;
    }

    event OrdenAleatorioCAR(TurnoLib.Turno turno, uint256[5] orden);
    event TurnoAsignado(TurnoLib.Turno turno, address asignado, string puesto);
    event TokensDistribuidos(
        address elegidoQ,
        uint256 premioQ,
        uint256 premioRestantePorPersona
    );
    event WalletAutorizada(address wallet, bool autorizado);
    event RotacionCARActualizada(address[5] nuevasDirecciones);
    event MasterCallerEjecutado(uint256 masterCallerNum, address ejecutadoPor, TurnoLib.Turno turno);


    /**
     * @dev Esta funcion es la que llama a las de car, q
     */
    function masterCallerOne(TurnoLib.Turno turno)
        public
        soloAutorizado
        hasImperivms
    {
        // Transfiere 1 IMP del usuario al contrato
        imperivmToken.transferFrom(msg.sender, address(this), 1 * (10**18));

        asignarCAR(turno);
        asignarQ(turno);

        distribuirTokens();

        emit MasterCallerEjecutado(1, msg.sender, turno);
    }


    function masterCallerTwo(TurnoLib.Turno turno)
        public
        soloAutorizado
        hasImperivms
    {
        // Transfiere 1 IMP del usuario al contrato
        imperivmToken.transferFrom(msg.sender, address(this), 1 * (10**18));

        asignarSecondary(turno);

        distribuirTokens();

        emit MasterCallerEjecutado(2, msg.sender, turno);
    }

    /**
     * @dev Asigna el puesto CAR en el turno actual. Genera un orden aleatorio para la asignación.
     * @param turno Turno actual para la asignación.
     * @return La dirección asignada al puesto CAR.
     */
    function asignarCAR(TurnoLib.Turno turno)
        internal
        soloAutorizado
        returns (uint256[5] memory)
    {
        require(turno.esTurnoCorrecto(), "Turno incorrecto");

        uint256 diaActual = block.timestamp / 1 days;
        InfoTurno storage infoTurnoActual = asignacionesTurno[turno];

        require(
            !(infoTurnoActual.asignadoEnEsteTurnoCAR &&
                infoTurnoActual.diaDeAsignacion == diaActual),
            "CAR ya asignado en este turno hoy"
        );

        if (infoTurnoActual.diaDeAsignacion != diaActual) {
            generarOrdenAleatorioCAR();
            infoTurnoActual.diaDeAsignacion = diaActual;
            indexActualCAR = 0;
        }

        //address asignado = rotacionCAR[ordenAleatorioCAR[indexActualCAR]];
        indexActualCAR = (indexActualCAR + 1) % rotacionCAR.length;
        infoTurnoActual.asignadoEnEsteTurnoCAR = true;

        emit OrdenAleatorioCAR(turno, ordenAleatorioCAR);

        return ordenAleatorioCAR;
    }

    /**
     * @dev Genera un orden aleatorio para la asignación de CAR.
     */
    function generarOrdenAleatorioCAR() internal {
        for (uint256 i = 0; i < ordenAleatorioCAR.length; i++) {
            ordenAleatorioCAR[i] = i;
        }

        for (uint256 i = 0; i < ordenAleatorioCAR.length; i++) {
            uint256 n = i +
                (uint256(
                    keccak256(abi.encodePacked(block.timestamp, msg.sender))
                ) % (ordenAleatorioCAR.length - i));
            uint256 temp = ordenAleatorioCAR[n];
            ordenAleatorioCAR[n] = ordenAleatorioCAR[i];
            ordenAleatorioCAR[i] = temp;
        }
    }

    /**
     * @dev Asigna el puesto Q en el turno actual. Evita la asignación repetida.
     * @param turno Turno actual para la asignación.
     * @return Índice de la wallet asignada a Q.
     */
    function asignarQ(TurnoLib.Turno turno)
        internal
        soloAutorizado
        returns (uint256)
    {
        require(turno.esTurnoCorrecto(), "Turno incorrecto");

        // Calcula el día actual
        uint256 diaActual = block.timestamp / 1 days;
        InfoTurno storage infoTurnoActual = asignacionesTurno[turno];

        // Verifica si Q ya ha sido asignado en este turno hoy
        require(
            !(infoTurnoActual.asignadoEnEsteTurnoQ &&
                infoTurnoActual.diaDeAsignacion == diaActual),
            "Q ya asignado en este turno hoy"
        );

        uint256 indexAleatorio;
        do {
            indexAleatorio = generarIndexAleatorio();
        } while (
            indexAleatorio == ultimoIndexQ ||
                !esWalletAutorizada[rotacionCAR[indexAleatorio]]
        );

        ultimoIndexQ = indexAleatorio;
        indexQ = indexAleatorio; // Asigna el índice actual de Q
        infoTurnoActual.asignadoEnEsteTurnoQ = true;
        infoTurnoActual.diaDeAsignacion = diaActual;

        emit TurnoAsignado(turno, rotacionCAR[indexAleatorio], "Q");
        return indexQ;
    }

    /**
     * @dev Asigna el puesto Secondary en el turno actual. Evita la asignación repetida.
     * @param turno Turno actual para la asignación.
     * @return Índice de la wallet asignada a Secondary.
     */
    function asignarSecondary(TurnoLib.Turno turno)
        internal
        soloAutorizado
        returns (uint256)
    {
        require(turno.esTurnoCorrecto(), "Turno incorrecto");

        uint256 diaActual = block.timestamp / 1 days;
        InfoTurno storage infoTurnoActual = asignacionesTurno[turno];

        require(
            !(infoTurnoActual.asignadoEnEsteTurnoSecondary &&
                infoTurnoActual.diaDeAsignacion == diaActual),
            "Secondary ya asignado en este turno hoy"
        );

        uint256 indexAleatorio;
        do {
            indexAleatorio = generarIndexAleatorio();
        } while (
            indexAleatorio == ultimoIndexSecondary ||
                !esWalletAutorizada[rotacionCAR[indexAleatorio]] ||
                indexAleatorio != indexQ
        );

        ultimoIndexSecondary = indexAleatorio;
        indexSecondary = indexAleatorio;
        infoTurnoActual.asignadoEnEsteTurnoSecondary = true;
        infoTurnoActual.diaDeAsignacion = diaActual;
        emit TurnoAsignado(turno, rotacionCAR[indexAleatorio], "SECONDARY");
        return indexSecondary;
    }

    /**
     * @dev Genera un índice aleatorio dentro del rango del array rotacionCAR.
     * @return Un índice aleatorio para la asignación de Q.
     * @notice Utiliza keccak256 para generar un hash pseudoaleatorio basado en el timestamp del bloque y el remitente.
     */
    function generarIndexAleatorio() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp, // Tiempo del bloque
                        msg.sender, // Dirección del remitente
                        gasleft(), // Gas restante
                        indexQ // Último índice Q asignado
                        // Puedes añadir más fuentes de entropía aquí
                    )
                )
            ) % rotacionCAR.length;
    }

    /**
     * @dev Obtiene la longitud del array rotacionCAR.
     * @return La longitud del array rotacionCAR.
     */
    function getRotacionCARlenght() public view returns (uint256) {
        return rotacionCAR.length;
    }

    /**
     * @dev Devuelve el orden actual aleatorio para CAR.
     * @return Array con el orden aleatorio actual.
     */
    function getOrdenActualCAR() public view returns (uint256[5] memory) {
        return ordenAleatorioCAR;
    }

    // Devuelve el índice actual asignado a Q
    function getQ() public view returns (uint256) {
        return indexQ;
    }

    // Devuelve el índice actual asignado a Secondary
    function getSecondary() public view returns (uint256) {
        return indexSecondary;
    }

    /**
     * @dev Verifica si la wallet del remitente está autorizada.
     * @return Verdadero si la wallet del remitente está autorizada, de lo contrario falso.
     */
    function isAutorizada() public view returns (bool) {
        return esWalletAutorizada[msg.sender];
    }


    /**
     * @dev Quita una dirección del array rotacionCAR y reorganiza el array para evitar espacios vacíos.
     * @param direccionARemover La dirección a ser removida de rotacionCAR.
     * @notice Mueve el último elemento del array a la posición de la dirección a remover, y establece la última posición a dirección cero.
     */
    function quitarDireccionDeRotacionCAR(address direccionARemover)
        public
        soloOwner
    {
        for (uint256 i = 0; i < rotacionCAR.length; i++) {
            if (rotacionCAR[i] == direccionARemover) {
                // Mover el último elemento a la posición del elemento a eliminar y establecer el último como dirección cero
                rotacionCAR[i] = rotacionCAR[rotacionCAR.length - 1];
                rotacionCAR[rotacionCAR.length - 1] = address(0);
                break;
            }
        }
    }

    /**
     * @dev Añade una nueva dirección al array rotacionCAR si hay espacio disponible y la autoriza.
     * @param nuevaDireccion La dirección a ser añadida a rotacionCAR y autorizada.
     * @notice Si no hay espacio disponible (ninguna dirección cero en rotacionCAR), la función se revierte con un mensaje de error.
     */
    function anadirDireccionARotacionCAR(address nuevaDireccion)
        public
        soloOwner
    {
        bool direccionAgregada = false;

        for (uint256 i = 0; i < rotacionCAR.length; i++) {
            if (rotacionCAR[i] == address(0)) {
                rotacionCAR[i] = nuevaDireccion;
                direccionAgregada = true;
                break;
            }
        }

        if (direccionAgregada) {
            // Autorizar la nueva dirección
            esWalletAutorizada[nuevaDireccion] = true;
        } else {
            // Manejar el caso en que el array esté lleno
            revert("La rotacion de CAR esta llena");
        }
    }

    /**
     * @dev Cambia el estado de autorización de una wallet.
     * @param wallet La dirección de la wallet cuyo estado de autorización será cambiado.
     * @param estado El nuevo estado de autorización para la wallet.
     */
    function cambiarEstadoWalletAutorizada(address wallet, bool estado)
        public
        soloOwner
    {
        esWalletAutorizada[wallet] = estado;
        emit WalletAutorizada(wallet, estado);
    }

    // Actualiza la rotación CAR con nuevas direcciones y actualiza las autorizaciones
    function actualizarRotacionCAR(address[5] memory nuevasDirecciones)
        public
        soloOwner
    {
        // Primero, desautorizar las direcciones actuales en rotacionCAR
        for (uint256 i = 0; i < 5; i++) {
            if (rotacionCAR[i] != address(0)) {
                esWalletAutorizada[rotacionCAR[i]] = false;
            }
        }

        // Luego, actualizar rotacionCAR con las nuevas direcciones y autorizarlas
        for (uint256 i = 0; i < 5; i++) {
            rotacionCAR[i] = nuevasDirecciones[i];
            if (nuevasDirecciones[i] != address(0)) {
                esWalletAutorizada[nuevasDirecciones[i]] = true;
                emit WalletAutorizada(nuevasDirecciones[i], true);
            }
        }

        emit RotacionCARActualizada(nuevasDirecciones);
    }

    function distribuirTokens() internal {
        uint256 premioQ = (1 * (10**18)) / 2; // 50% para el elegido en Q
        uint256 premioRestantePorPersona = premioQ / 4; // Dividido entre los 4 restantes

        // Transferir 50% al elegido para Q
        address elegidoQ = rotacionCAR[indexQ];
        imperivmToken.transfer(elegidoQ, premioQ);

        // Distribuir el 50% restante entre los demás
        for (uint256 i = 0; i < rotacionCAR.length; i++) {
            if (i != indexQ) {
                // Excluyendo al elegido para Q
                imperivmToken.transfer(
                    rotacionCAR[i],
                    premioRestantePorPersona
                );
            }
            emit TokensDistribuidos(
                elegidoQ,
                premioQ,
                premioRestantePorPersona
            );
        }
    }
}

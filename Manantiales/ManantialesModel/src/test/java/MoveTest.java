/**
 * Tests for moves in Manantiales. Covers all types, but not all moves, possible.
 *
 * Originally written to debug duplicate move problem detected in MG-116
 *
 * @author awaterma@ecosur.mx
 */
import com.mockrunner.ejb.EJBTestModule;
import com.mockrunner.jms.JMSTestCaseAdapter;
import com.mockrunner.mock.jms.MockTopic;

import mx.ecosur.multigame.enums.GameState;
import mx.ecosur.multigame.enums.MoveStatus;
import mx.ecosur.multigame.exception.InvalidMoveException;
import mx.ecosur.multigame.grid.entity.GridPlayer;
import mx.ecosur.multigame.grid.entity.GridRegistrant;
import mx.ecosur.multigame.manantiales.entity.ManantialesFicha;
import mx.ecosur.multigame.manantiales.entity.ManantialesGame;
import mx.ecosur.multigame.manantiales.entity.ManantialesMove;
import mx.ecosur.multigame.manantiales.entity.ManantialesPlayer;

import mx.ecosur.multigame.manantiales.enums.Mode;
import mx.ecosur.multigame.manantiales.enums.TokenType;
import mx.ecosur.multigame.model.interfaces.GamePlayer;
import org.junit.Before;
import org.junit.Test;

import javax.jms.JMSException;

import static util.TestUtilities.*;

public class MoveTest extends JMSTestCaseAdapter {

    private ManantialesGame game;

    private ManantialesPlayer alice, bob, charlie, denise;

    private MockTopic mockTopic;

    private EJBTestModule ejbModule;

    @Before
    public void setUp() throws Exception {
        super.setUp();
        game = new ManantialesGame();
        game.setMode(Mode.SILVO_PUZZLE);

        /* Set up mock JMS destination for message sender */
        ejbModule = createEJBTestModule();
        ejbModule.bindToContext("MultiGameConnectionFactory",
                getJMSMockObjectFactory().getMockTopicConnectionFactory());
        mockTopic = getDestinationManager().createTopic("MultiGame");
        ejbModule.bindToContext("MultiGame", mockTopic);

        GridRegistrant[] players = {
                new GridRegistrant ("alice"),
                new GridRegistrant ("bob"),
                new GridRegistrant ("charlie"),
                new GridRegistrant ("denise") };

        for (GridRegistrant registrant : players) {
            game.registerPlayer(registrant);
        }

        for (GridPlayer player : game.getPlayers()) {
            if (player.getName().equals("alice")) {
                alice = (ManantialesPlayer) player;
            } else if (player.getName().equals("bob")) {
                bob = (ManantialesPlayer) player;
            } else if (player.getName().equals("charlie")) {
                charlie = (ManantialesPlayer) player;
            } else if (player.getName().equals("denise")) {
                denise = (ManantialesPlayer)player;
            }
        }
    }

    @Test
    public void testSetup() {
        assertNotNull(game.getPlayers());
        assertTrue(game.getState().equals(GameState.PLAY));
    }

    /**
     * Tests a move of a current
     */
    @Test
    public void testMove() throws InvalidMoveException {
        ManantialesFicha f1 = new ManantialesFicha(0,4, bob.getColor(),
                TokenType.MODERATE_PASTURE);
        ManantialesFicha f2 = new ManantialesFicha(1,4, bob.getColor(),
                TokenType.MODERATE_PASTURE);
        SetIds(f1, f2);
        ManantialesMove move = new ManantialesMove(alice, f1);
        game.move(move);
        /* Cleanup players */
        removeTurns();
        alice.setTurn(true);
        /* Do new move */
        move = new ManantialesMove (alice, f1, f2);
        game.move(move);
        assertNull(game.getGrid().getLocation(f1));
        assertEquals(MoveStatus.EVALUATED, move.getStatus());
    }

    @Test
    public void testMoveModerate() throws JMSException, InvalidMoveException {
        ManantialesFicha man1 = new ManantialesFicha(0,4, bob.getColor(),
                TokenType.MODERATE_PASTURE);
        ManantialesFicha man2 = new ManantialesFicha(1,4, bob.getColor(),
                TokenType.MODERATE_PASTURE);
        SetIds(man1, man2);
        removeTurns();

        bob.setTurn(true);
        ManantialesMove move = new ManantialesMove(bob, man1);
        game.move(move);
        removeTurns();

        bob.setTurn(true);
        move = new ManantialesMove(bob,man1,man2);
        game.move(move);
        removeTurns();

        assertNull(game.getGrid().getLocation(man1));
        assertEquals (MoveStatus.EVALUATED, move.getStatus());
    }

    /**
     * Test for MG-120 in regular puzzle.
     */
    @Test
    public void testCompetitiveReplacement() throws JMSException, InvalidMoveException {
        game.setMode(Mode.COMPETITIVE);
        ManantialesFicha man1 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.MANAGED_FOREST);
        ManantialesFicha man2 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.INTENSIVE_PASTURE);
        SetIds(man1, man2);
        removeTurns();

        alice.setTurn(true);
        ManantialesMove move = new ManantialesMove(alice, man1);
        move.setMode(Mode.COMPETITIVE);
        game.move(move);
        removeTurns();

        alice.setTurn(true);
        move = new ManantialesMove(alice,man1,man2);
        move.setMode(Mode.COMPETITIVE);
        game.move(move);
        removeTurns();
        assertEquals (MoveStatus.INVALID, move.getStatus());
    }

    /**
     * Test for MG-120 in regular puzzle.
     */
    @Test
    public void testPuzzleReplacement() throws JMSException, InvalidMoveException {
        game.setMode(Mode.BASIC_PUZZLE);
        ManantialesFicha man1 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.MANAGED_FOREST);
        ManantialesFicha man2 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.INTENSIVE_PASTURE);
        SetIds(man1, man2);
        removeTurns();

        alice.setTurn(true);
        ManantialesMove move = new ManantialesMove(alice, man1);
        move.setMode(Mode.BASIC_PUZZLE);
        game.move(move);
        removeTurns();

        alice.setTurn(true);
        move = new ManantialesMove(alice,man1,man2);
        move.setMode(Mode.BASIC_PUZZLE);
        game.move(move);
        removeTurns();
        assertEquals(MoveStatus.EVALUATED, move.getStatus());
    }
    /**
     * Test for MG-120 in SILVO_PUZZLE.
     *
     * Intensive replaces managed forest
     */
    @Test
    public void testSilvoPuzzleReplacement1() throws JMSException, InvalidMoveException {
        game.setMode(Mode.SILVO_PUZZLE);
        ManantialesFicha man1 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.MANAGED_FOREST);
        ManantialesFicha man2 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.INTENSIVE_PASTURE);
        SetIds(man1, man2);
        removeTurns();

        alice.setTurn(true);
        ManantialesMove move = new ManantialesMove(alice, man1);
        move.setMode(Mode.SILVO_PUZZLE);
        game.move(move);
        removeTurns();

        alice.setTurn(true);
        move = new ManantialesMove(alice,man1,man2);
        move.setMode(Mode.SILVO_PUZZLE);
        game.move(move);
        removeTurns();
        assertEquals("Wrong move status! " + move.getStatus(), MoveStatus.EVALUATED, move.getStatus());
    }

    /**
     * Test for MG-120 in SILVO_PUZZLE.
     *
     * Intensive replaces silvopastoral
     */
    @Test
    public void testSilvoPuzzleReplacement2() throws JMSException, InvalidMoveException {
        game.setMode(Mode.SILVO_PUZZLE);
        ManantialesFicha man1 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.SILVOPASTORAL);
        ManantialesFicha man2 = new ManantialesFicha(0,4, alice.getColor(),
                TokenType.INTENSIVE_PASTURE);
        SetIds(man1, man2);
        removeTurns();

        alice.setTurn(true);
        ManantialesMove move = new ManantialesMove(alice, man1);
        move.setMode(Mode.SILVO_PUZZLE);
        game.move(move);
        removeTurns();

        alice.setTurn(true);
        move = new ManantialesMove(alice,man1,man2);
        move.setMode(Mode.SILVO_PUZZLE);
        game.move(move);
        removeTurns();
        assertEquals("Wrong move status! " + move.getStatus(), MoveStatus.EVALUATED, move.getStatus());
    }

    private void removeTurns() {
        for (GamePlayer p : game.getPlayers()) {
            ManantialesPlayer player = (ManantialesPlayer) p;
            player.setTurn(false);
        }
    }
}

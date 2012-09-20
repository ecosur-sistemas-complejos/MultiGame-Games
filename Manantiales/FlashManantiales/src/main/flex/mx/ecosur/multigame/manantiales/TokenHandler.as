package mx.ecosur.multigame.manantiales {

    import flash.events.MouseEvent;
    import mx.collections.ArrayCollection;
    import mx.core.DragSource;
    import mx.core.IFlexDisplayObject;
    import mx.ecosur.multigame.component.BoardCell;
    import mx.ecosur.multigame.entity.Cell;
    import mx.ecosur.multigame.enum.MoveStatus;
    import mx.ecosur.multigame.manantiales.entity.Ficha;
    import mx.ecosur.multigame.manantiales.entity.ManantialesMove;
    import mx.ecosur.multigame.manantiales.entity.ManantialesPlayer;
    import mx.ecosur.multigame.manantiales.enum.TokenType;
    import mx.ecosur.multigame.manantiales.token.ForestToken;
    import mx.ecosur.multigame.manantiales.token.IntensiveToken;
    import mx.ecosur.multigame.manantiales.token.ManantialesToken;
    import mx.ecosur.multigame.manantiales.token.ManantialesTokenStore;
    import mx.ecosur.multigame.manantiales.token.ModerateToken;
    import mx.ecosur.multigame.manantiales.token.SilvopastoralToken;
    import mx.ecosur.multigame.manantiales.token.UndevelopedToken;
    import mx.ecosur.multigame.manantiales.token.ViveroToken;
    import mx.events.DragEvent;
    import mx.managers.DragManager;

    public class TokenHandler {

        private var _currentPlayer:ManantialesPlayer;

        private var _suggestionHandler:SuggestionHandler;

        private var _gameWindow:ManantialesWindow;

        private var _tokenStores:ArrayCollection;

        private var _mode:String;

        private var _isMoving:Boolean;

        private var _altDown:Boolean;

        public function TokenHandler(gameWindow:ManantialesWindow, player:ManantialesPlayer, handler:SuggestionHandler)
        {
            _currentPlayer = player;
            _suggestionHandler = handler;
            _gameWindow = gameWindow;
            _tokenStores = new ArrayCollection();
            _mode = gameWindow.currentState;
        }

        public function update (player:ManantialesPlayer):void {
            _currentPlayer = player;
        }

        public function processViolator (ficha:Ficha):void {
            if (ficha.color == _currentPlayer.color) {
                for (var i:int = 0; i < _tokenStores.length; i++) {
                    var store:ManantialesTokenStore = ManantialesTokenStore(_tokenStores.getItemAt(i));
                    if (store.tokenType == ficha.type) {
                        store.addToken();
                        break;
                    }
                }
            }
        }

        public function resetTokenStores():void {
            // initialize token stores
            for (var i:int = 0; i < _tokenStores.length; i++) {
                var store:ManantialesTokenStore = ManantialesTokenStore(_tokenStores.getItemAt(i));
                store.fill();
            }
        }

        public function initializeTokenStores ():void {
            // setup token store panels for hiding
            if (_tokenStores.getItemIndex(_gameWindow.forestStore) < 0)
                _tokenStores.addItem(_gameWindow.forestStore);
            if (_tokenStores.getItemIndex(_gameWindow.moderateStore) < 0)
                _tokenStores.addItem(_gameWindow.moderateStore);
            if (_tokenStores.getItemIndex(_gameWindow.intensiveStore) < 0)
                _tokenStores.addItem(_gameWindow.intensiveStore);

            if (_gameWindow.currentState == "SILVOPASTORAL" || _gameWindow.currentState == "SILVO_PUZZLE") {
                if (_tokenStores.getItemIndex(_gameWindow.viveroStore) < 0)
                    _tokenStores.addItem(_gameWindow.viveroStore);
                if (_tokenStores.getItemIndex(_gameWindow.silvoStore) < 0)
                    _tokenStores.addItem(_gameWindow.silvoStore);
            }

            // initialize token stores
            for (var i:int = 0; i < _tokenStores.length; i++) {
                var store:ManantialesTokenStore = ManantialesTokenStore(_tokenStores.getItemAt(i));
                if (store)
                    initializeTokenStore (store);
            }
        }

        private function initializeTokenStore (tokenStore:ManantialesTokenStore):void {
            tokenStore.startMoveHandler = dragStart;
            tokenStore.endMoveHandler = endMove;
            tokenStore.visible = true;
            tokenStore.active = true;
            tokenStore.init(_currentPlayer);
        }

        public function dragDropCell(evt:DragEvent):ManantialesMove {

            var suggestion:Boolean;
            var _executingMove:ManantialesMove;

            if (evt.dragSource.hasFormat("token"))
            {
                var sourceToken:ManantialesToken = ManantialesToken (evt.dragSource.dataForFormat("token"));
                var sourceCell:Cell = Cell(evt.dragSource.dataForFormat("cell"));

                // define destination
                var destination:Ficha = Ficha(sourceToken.ficha);


                // define the move
                var move:ManantialesMove = new ManantialesMove();
                move.status = String (MoveStatus.UNVERIFIED);
                move.mode = _mode;
                move.id = 0;

                // define target cell
                var targetCell:BoardCell = BoardCell(evt.currentTarget);
                if (targetCell.token.cell != null) {
                    move.currentCell = Ficha (targetCell.token.cell);
                }

                /* Set the move's current cell based upon what token's located at the target */
                var targetToken:ManantialesToken = ManantialesToken (targetCell.token);
                if (sourceCell != null) {
                    move.currentCell = sourceCell;
                    /* No swaps, will add support later, if possible (we get duplicate primary key violation currently) */
                    /*if (targetToken != null && targetToken.cell != null) {
                        move.swap = true
                    }*/
                }

                /* Set the destination information to match where the token was dragged to */
                destination.row = targetCell.row;
                destination.column = targetCell.column;
                destination.type = sourceToken.ficha.type;
                move.destinationCell = destination;
                move.mode = _mode;

                /* We only set the "current cell" to an Undeveloped token when it is not null,
                   i.e., when an existing token is being moved or a suggestion for another player
                   has been created.
                 */
                if (move.currentCell != null && !move.swap) {
                    targetToken  = new UndevelopedToken();
                    var source:RoundCell = RoundCell(_gameWindow.board.getBoardCell(move.currentCell.column,
                            move.currentCell.row));
                    source.token = targetToken;
                    source.reset();
                } else if (move.currentCell != null && move.swap) {
                    switch (destination.type) {
                        case TokenType.FOREST:
                            targetToken = new ForestToken();
                            break;
                        case TokenType.INTENSIVE:
                            targetToken = new IntensiveToken();
                            break;
                        case TokenType.MODERATE:
                            targetToken = new ModerateToken();
                            break;
                        case TokenType.SILVOPASTORAL:
                            targetToken = new SilvopastoralToken();
                            break;
                        case TokenType.VIVERO:
                            targetToken = new ViveroToken();
                            break;
                        default:
                            trace("Default in switch!!");
                            trace("type: " + destination.type);
                            targetToken = new UndevelopedToken();
                    }
                    var source:RoundCell = RoundCell(_gameWindow.board.getBoardCell(move.currentCell.column,
                            move.currentCell.row));
                    source.token = targetToken;
                    source.reset();
                }

                /* TODO: This switch needs cleaning up, and is not currently accurate (if working) */
                if (move.currentCell == null && sourceToken.cell.color == _currentPlayer.color) {
                    /* Regular Move */
                    move.player = _currentPlayer;
                    decrementStore(Ficha (move.destinationCell));
                     _gameWindow.controller.sendMove(move);

                } else if (destination.color == _currentPlayer.color && move.currentCell != null) {
                    /* Replacement move */
                    decrementStore(Ficha (move.destinationCell));
                    if (move.currentCell instanceof Ficha)
                        incrementStore(Ficha (move.currentCell));
                    else
                        move.currentCell = null;    // hack
                    move.player = _currentPlayer;
                    _gameWindow.controller.sendMove(move);

                } else if (destination.color != _currentPlayer.color) {
                    /* Suggestion to another player */
                    suggestion = true;
                    move.player = null;
                    _suggestionHandler.makeSuggestion(move);
                } else {
                    throw new Error ("ERROR! Unable to create move/suggestion!");
                }

                // animate
                targetCell.reset();

                var newToken:ManantialesToken;

                if (sourceToken is ForestToken) {
                    newToken = new ForestToken();
                }
                else if (sourceToken is IntensiveToken) {
                    newToken = new IntensiveToken();
                }
                else if (sourceToken is ModerateToken) {
                    newToken = new ModerateToken();
                }
                else if (sourceToken is ViveroToken) {
                    newToken = new ViveroToken();
                }
                else if (sourceToken is SilvopastoralToken) {
                    newToken = new SilvopastoralToken();
                }

                newToken.cell = destination;

                if (_gameWindow.controller.puzzleMode)
                    addListeners (newToken);

                _gameWindow.board.addToken(newToken);
            }

            return _executingMove;
        }

        private function decrementStore(ficha:Ficha):void {
            switch (ficha.type) {
                case TokenType.FOREST:
                    _gameWindow.forestStore.removeToken();
                    break;
                case TokenType.INTENSIVE:
                    _gameWindow.intensiveStore.removeToken();
                    break;
                case TokenType.MODERATE:
                    _gameWindow.moderateStore.removeToken();
                    break;
                case TokenType.VIVERO:
                    _gameWindow.viveroStore.removeToken();
                    break;
                case TokenType.SILVOPASTORAL:
                    _gameWindow.silvoStore.removeToken();
                    break;
                default:
                    break;
            }            
        }

        private function incrementStore (ficha:Ficha):void {
            switch (ficha.type) {
                case TokenType.FOREST:
                    _gameWindow.forestStore.addToken();
                    break;
                case TokenType.INTENSIVE:
                    _gameWindow.intensiveStore.addToken();
                    break;
                case TokenType.MODERATE:
                    _gameWindow.moderateStore.addToken();
                    break;
                case TokenType.VIVERO:
                    _gameWindow.viveroStore.addToken();
                    break;
                case TokenType.SILVOPASTORAL:
                    _gameWindow.silvoStore.addToken();
                    break;
                default:
                    break;
            }

        }

        public function dragExitCell(evt:DragEvent):void{

            // unselect board cell
            if (evt.dragSource.hasFormat("token")){
                var boardCell:BoardCell = BoardCell(evt.currentTarget);
                boardCell.reset();
            }
        }

        public function isTurn():Boolean {
            return _currentPlayer.turn;
        }

        public function dragStart(evt:MouseEvent):void {
            // initialize drag source
            var token:ManantialesToken = ManantialesToken(evt.currentTarget);
            var ds:DragSource = new DragSource();
            ds.addData(token, "token");
            if (token.cell != null)
                ds.addData(token.cell, "cell");
            // create proxy image and start drag
            var dragImage:IFlexDisplayObject = token.createDragImage();
            var previous:ManantialesToken = ManantialesToken(evt.currentTarget);
            // Add previous to the drag source
            ds.addData(previous,"source");
            /* Drag Start initiated last for clean event propagation */
            DragManager.doDrag(token, ds, evt, dragImage);
            _isMoving = true;
        }

        public function endMove(evt:DragEvent):void{

            if (evt.dragSource.hasFormat("token")){
                _isMoving = false;
                var token:ManantialesToken = ManantialesToken(evt.currentTarget);
                token.selected = false;
                token.play();

                // remove dragged image
                if (evt.dragSource is ManantialesToken) {
                    var previous:ManantialesToken = ManantialesToken (evt.dragSource);
                    if (previous != null && previous.ficha.column > 0 && previous.ficha.row > 0) {
                        var boardCell:BoardCell = _gameWindow.board.getBoardCell(previous.cell.column, previous.cell.row);
                        var undeveloped:UndevelopedToken = new UndevelopedToken();
                        undeveloped.cell = previous.cell;
                        boardCell.token = undeveloped;
                        boardCell.reset();
                    }
                }
            }
        }

        public function addListeners (token:ManantialesToken):void {
            if (token.cell) {
                if(token.cell.color == _currentPlayer.color){
                     token.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
                     token.addEventListener(DragEvent.DRAG_COMPLETE, endMove);
                }else{
                    token.addEventListener(MouseEvent.MOUSE_DOWN, _suggestionHandler.dispatch);
                    token.addEventListener(DragEvent.DRAG_COMPLETE, _suggestionHandler.endSuggestion);
                }
            }
        }                               
    }
}

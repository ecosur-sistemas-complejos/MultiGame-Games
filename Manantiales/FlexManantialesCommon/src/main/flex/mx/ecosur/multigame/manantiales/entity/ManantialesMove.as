package mx.ecosur.multigame.manantiales.entity {

    import mx.ecosur.multigame.entity.GamePlayer;
    import mx.ecosur.multigame.entity.Move;

    [RemoteClass (alias=
        "mx.ecosur.multigame.manantiales.entity.ManantialesMove")]
    public class ManantialesMove extends Move
    {
        private var _badYear:Boolean;

        private var _mode:String;
        
        private var _swap:Boolean;

        private var _type:String;

        private var _premium:Boolean;

        private var _playerModel:GamePlayer;
        
        private var _replacementType:String;

        public function ManantialesMove()
        {
            super();
            _badYear = false;
        }

        public function get playerModel():GamePlayer {
            return _playerModel;
        }

        public function set playerModel(value:GamePlayer):void {
            _playerModel = value;
        }

        public function get premium():Boolean {
            return _premium;
        }

        public function set premium(value:Boolean):void {
            _premium = value;
        }

        public function get swap():Boolean {
            return _swap;
        }
        
        public function set swap(swap:Boolean):void {
            _swap = swap;
        }

        public function get badYear():Boolean {
            return _badYear;
        }

        public function set badYear (year:Boolean):void {
            _badYear = year;
        }

        public function get mode ():String {
            return _mode;
        }

        public function set mode (mode:String):void {
            _mode = mode;
        }

        public function get type():String {
            return _type;
        }

        public function set type(value:String):void {
            _type = value;
        }

        public function get replacementType():String {
            return _replacementType;
        }

        public function set replacementType(value:String):void {
            _replacementType = value;
        }

        public override function toString():String {
            return "ManantialesMove [ current=" + currentCell + ", destination=" + destinationCell + ",swap=" + _swap +
                ",mode=" + mode + ", type=" + type + ", replacementType=" + replacementType;
        }
    }
}

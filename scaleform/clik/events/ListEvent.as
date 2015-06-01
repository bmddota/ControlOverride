/**
 *  Event structure and defintions for the CLIK ScrollingList: 
 *  Valid types:
 *      ITEM_CLICK - "indexChange"
 *      ITEM_PRESS - "itemPress"
 *      ITEM_ROLL_OVER - "itemRollOver"
 *      ITEM_ROLL_OUT - "itemRollOut"
 *      ITEM_DOUBLE_CLICK - "itemDoubleClick"
 *      INDEX_CHANGE - "indexChange"
 */

/**************************************************************************

Filename    :   ListEvent.as

Copyright   :   Copyright 2011 Autodesk, Inc. All Rights reserved.

Use of this software is subject to the terms of the Autodesk license
agreement provided at the time of installation or download, or which
otherwise accompanies this software in either electronic or hard copy form.

**************************************************************************/
 
package scaleform.clik.events {
    
    import flash.events.Event;
    
    import scaleform.clik.controls.Button;
    import scaleform.clik.interfaces.IListItemRenderer;
    
    public class ListEvent extends Event {
        
    // Constants:
        public static const ITEM_CLICK:String = "itemClick";
        public static const ITEM_PRESS:String = "itemPress";
        public static const ITEM_ROLL_OVER:String = "itemRollOver";
        public static const ITEM_ROLL_OUT:String = "itemRollOut";
        public static const ITEM_DOUBLE_CLICK:String = "itemDoubleClick";
        public static const INDEX_CHANGE:String = "listIndexChange";
        
    // Public Properties:
        /** A reference to the related IListItemRenderer. */
        public var itemRenderer:IListItemRenderer;
        /** The data associated with the related IListItemRenderer. */
        public var itemData:Object;
        
        /** The index of the related IListItemRenderer relative to the List. */
        public var index:int = -1;
        /** The column index of the related IListItemRenderer. */
        public var columnIndex:int = -1; // Unimplemented.
        /** The row index of the related IListItemRenderer.*/
        public var rowIndex:int = -1; // Unimplemented.
        
        /** The index of the controller/mouse used to generate the event (applicable only for multi-mouse cursor environments). */
        public var controllerIdx:uint = 0;
        /** The index of the button on the controller/mouse used to generate the event. */
        public var buttonIdx:uint = 0;
        /** true if the event was generated by keyboard or gamepad input; false otherwise. */
        public var isKeyboard:Boolean = false;
        
    // Protected Properties:
        
    // Initialization:
        public function ListEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = true, 
                                  index:int = -1, columnIndex:int = -1, rowIndex:int = -1, 
                                  itemRenderer:IListItemRenderer = null, itemData:Object = null, 
                                  controllerIdx:uint = 0, buttonIdx:uint = 0, isKeyboard:Boolean = false) 
        {
            super(type, bubbles, cancelable);
            
            this.itemRenderer = itemRenderer;
            this.itemData = itemData;
            
            this.index = index;
            this.rowIndex = rowIndex;
            this.columnIndex = columnIndex;
            
            this.controllerIdx = controllerIdx;
            this.buttonIdx = buttonIdx;
            this.isKeyboard = isKeyboard;
        }
        
    // Public getter / setters:
        
    // Public Methods:
        override public function clone():Event {
            return new ListEvent(type, bubbles, cancelable, index, columnIndex, rowIndex, itemRenderer, itemData, controllerIdx, buttonIdx, isKeyboard);
        }
        
        override public function toString():String {
            return formatToString("ListEvent", "type", "bubbles", "cancelable", "index", "columnIndex", "rowIndex", "itemRenderer", "itemData", "controllerIdx", "buttonIdx", "isKeyboard");
        }
        
    // Protected Methods:
        
    }
    
}
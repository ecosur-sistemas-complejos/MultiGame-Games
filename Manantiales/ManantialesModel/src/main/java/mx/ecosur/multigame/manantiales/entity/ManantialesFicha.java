/*
* Copyright (C) 2010 ECOSUR, Andrew Waterman and Max Pimm
*
* Licensed under the Academic Free License v. 3.2.
* http://www.opensource.org/licenses/afl-3.0.php
*/

/**
* @author awaterma@ecosur.mx
*/
package mx.ecosur.multigame.manantiales.entity;

import javax.persistence.*;

import mx.ecosur.multigame.grid.entity.GridCell;
import mx.ecosur.multigame.manantiales.enums.BorderType;
import mx.ecosur.multigame.manantiales.enums.TokenType;
import org.apache.commons.lang.builder.HashCodeBuilder;

import mx.ecosur.multigame.grid.Color;

@Entity
public class ManantialesFicha extends GridCell implements Comparable<ManantialesFicha> {

    private static final long serialVersionUID = -8048552960014554186L;
    private TokenType type;

    public ManantialesFicha() {
        super();
    }

    public ManantialesFicha(int column, int row, Color color, TokenType type) {
        super(column, row, color);
        this.type = type;
    }

    @Enumerated (EnumType.STRING)
    public TokenType getType() {
        return type;
    }

    public void setType(TokenType type) {
        this.type = type;
    }

    /**
     * @return theScore
     */
    @Transient
    public int score () {
        int ret = 0;
        if (type != null)
            ret = type.value();
        return ret;
    }

    @Transient
    public BorderType getBorder () {
        BorderType ret = BorderType.NONE;
        if (this.getRow() == 4) {
            if (this.getColumn() < 4)
                ret = BorderType.WEST;
            else if (this.getColumn() > 4)
                ret = BorderType.EAST;
        } else if (this.getColumn() == 4) {
            if (this.getRow () < 4)
                ret = BorderType.NORTH;
            else if (this.getRow () > 4)
                ret = BorderType.SOUTH;
        }

        return ret;
    }

    /**
     * @return
     */
    @Transient
    public boolean isManantial() {
        if (type.equals(TokenType.UNDEVELOPED))
            return false;

        /* Check all other tokens */
        boolean ret = false;
        if (this.getColumn() == 3 && this.getRow() == 4)
            ret = true;
        else if (this.getColumn() == 4  && this.getRow() == 3)
            ret = true;
        else if (this.getColumn() == 5 && this.getRow() == 4)
            ret = true;
        else if (this.getColumn() == 4 && this.getRow() == 5)
            ret = true;
        return ret;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#equals(java.lang.Object)
     */
    @Override
    public boolean equals(Object obj) {
        boolean ret = false;
        if (obj instanceof ManantialesFicha) {
            ManantialesFicha comp = (ManantialesFicha) obj;
            ret = (comp.type.equals(this.type) &&
                    comp.getRow() == getRow() &&
                    comp.getColumn() == getColumn() &&
                    comp.getColor() == getColor());
        }

        return ret;
    }

    @Override
    public int compareTo(ManantialesFicha comp) {
        if (this.equals(comp)) {
            return 0;
        } else if (this.getId() != 0 && comp.getId() != 0) {
            if (this.getId() > comp.getId()) {
                return 1;
            } if (this.getId() == comp.getId()) {
                return 0;
            } else {
                return -1;
            }
        } else {
            if (this.getRow() > comp.getRow()) {
                return 1;
            } else if (this.getRow() < comp.getRow()) {
                return -1;
            } else if (this.getColumn() > comp.getColumn()) {
                return 1;
            } else if (this.getColumn() < comp.getColumn()) {
                return -1;
            }
        }

        return 0;
    }
    /* (non-Javadoc)
     * @see java.lang.Object#hashCode()
     */
    @Override
    public int hashCode() {
        return new HashCodeBuilder()
        .append(getColumn())
        .append(getRow())
        .append(getType())
        .append(getColor())
        .toHashCode();
    }

    /* (non-Javadoc)
     * @see mx.ecosur.multigame.entity.Cell#toString()
     */
    @Override
    public String toString() {
        return "[Ficha, type = " + type + ", " + super.toString();
    }

}

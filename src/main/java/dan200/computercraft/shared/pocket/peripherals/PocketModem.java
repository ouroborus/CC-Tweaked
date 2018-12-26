package dan200.computercraft.shared.pocket.peripherals;

import dan200.computercraft.api.peripheral.IPeripheral;
import dan200.computercraft.api.pocket.IPocketAccess;
import dan200.computercraft.shared.peripheral.PeripheralType;
import dan200.computercraft.shared.peripheral.common.PeripheralItemFactory;
import dan200.computercraft.shared.peripheral.modem.ModemState;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityLivingBase;
import net.minecraft.util.ResourceLocation;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

public class PocketModem extends AbstractPocketUpgrade
{
    private final boolean advanced;

    public PocketModem( boolean advanced )
    {
        super(
            advanced
                ? new ResourceLocation( "computercraft", "advanved_modem" )
                : new ResourceLocation( "computercraft", "wireless_modem" ),
            advanced
                ? "upgrade.computercraft:advanced_modem.adjective"
                : "upgrade.computercraft:wireless_modem.adjective",
            PeripheralItemFactory.create(
                advanced ? PeripheralType.AdvancedModem : PeripheralType.WirelessModem,
                null, 1
            )
        );
        this.advanced = advanced;
    }

    @Nullable
    @Override
    public IPeripheral createPeripheral( @Nonnull IPocketAccess access )
    {
        return new PocketModemPeripheral( advanced );
    }

    @Override
    public void update( @Nonnull IPocketAccess access, @Nullable IPeripheral peripheral )
    {
        if( !(peripheral instanceof PocketModemPeripheral) ) return;

        Entity entity = access.getEntity();

        PocketModemPeripheral modem = (PocketModemPeripheral) peripheral;
        if( entity instanceof EntityLivingBase )
        {
            EntityLivingBase player = (EntityLivingBase) entity;
            modem.setLocation( entity.getEntityWorld(), player.posX, player.posY + player.getEyeHeight(), player.posZ );
        }
        else if( entity != null )
        {
            modem.setLocation( entity.getEntityWorld(), entity.posX, entity.posY, entity.posZ );
        }

        ModemState state = modem.getModemState();
        if( state.pollChanged() ) access.setLight( state.isOpen() ? 0xBA0000 : -1 );
    }
}

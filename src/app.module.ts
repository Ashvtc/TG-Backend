import { Module } from '@nestjs/common';
import { UserModule } from './user/infrastructure/user.module';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RolModule } from './rol/infrastructure/rol.module';
import { RoomModule } from './room/infrastructure/room.module';
import { CleaningTypeModule } from './cleaningType/infrastructure/cleaning-type.module';
import { CleaningCheckModule } from './cleaningCheck/infrastructure/cleaning-check.module';
import { CleaningActionModule } from './cleaningAction/infrastructure/cleaning-action.module';
import { PermissionsModule } from './permissions/infrastructure/permissions.module';
import { PrinterModule } from './printer/printer.module';
import { AreaModule } from './area/infrastructure/area.module';

@Module({
  imports: [UserModule, RolModule, RoomModule, CleaningTypeModule,
    CleaningCheckModule, CleaningActionModule, PrinterModule,
    ConfigModule.forRoot(),

    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: +process.env.DB_PORT,
      database: process.env.DB_NAME,
      username: process.env.DB_USERNAME,
      password: process.env.DB_PASS,
      autoLoadEntities: true,
      synchronize: process.env.DB_SYNC === 'true'
    }),

    PermissionsModule,

    AreaModule,
  ],
})
export class AppModule {}

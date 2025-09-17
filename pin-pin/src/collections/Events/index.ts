import type { CollectionConfig } from 'payload'

import { authenticated } from '../../access/authenticated'

export const Events: CollectionConfig = {
  slug: 'marketplaceEvents',
  access: {
    create: authenticated,
    delete: authenticated,
    read: authenticated,
    update: authenticated,
  },
  admin: {
    defaultColumns: ['pin'],
    useAsTitle: 'pin',
  },
  fields: [
    {
      name: 'pin',
      type: 'relationship',
      relationTo: 'pins',
      hasMany: false,
      required: true,
    },
    {
        name:'transactionID',
        type: 'text',
        required: true,
    },
    {
      name: 'eventType',
      type: 'select',
      options: [
        {
          label: 'Buy',
          value: 'buy',
        },
        {
          label: 'Sell',
          value: 'sell',
        },
        {
          label: 'Listing',
          value: 'listing',
        },
        {
          label: 'Unlisting',
          value: 'unlisting',
        },
        {
          label: 'Trade',
          value: 'trade',
        },
      ],
    },
    {
      name: 'price',
      type: 'number',
      required: false,
    },
    {
      name: 'seller',
      type: 'text',
      required: false,
    },
    {
      name: 'buyer',
      type: 'text',
      required: false,
    },
    {
        name: 'alertMedium',
        type: 'group',
        fields: [
          {
            name: 'email',
            type: 'checkbox',
            defaultValue: true,
          },
          {
            name: 'discord',
            type: 'checkbox',
            defaultValue: false,
          },
          {
            name: 'telegram',
            type: 'checkbox',
            defaultValue: false,
          },
        ],
        required: true,
    }
  ],
  timestamps: true,
}
import type { CollectionConfig } from 'payload'

import { authenticated } from '../../access/authenticated'

export const Pins: CollectionConfig = {
  slug: 'pins',
  access: {
    create: authenticated,
    delete: authenticated,
    read: authenticated,
    update: authenticated,
  },
  admin: {
    defaultColumns: ['title'],
    useAsTitle: 'title',
  },
  fields: [
    {
        name: 'user',
        type: 'relationship',
        required: true,
        relationTo: 'users',
        hasMany: false,
        admin: {
          position: 'sidebar',
        },
    },
    {
      name:'active',
      type: 'checkbox',
      required: true,
      defaultValue: true,
      admin: {
        position: 'sidebar',
      },
    },
    {
      name: 'editionID',
      type: 'text',
      required: true,
    },
    {
      name:'title',
      type: 'text',
      required: true,
    },
    {
      name:'belowPrice',
      type: 'number',
    },
  ],    
  timestamps: true, 
}